extends Node2D

# Rün büyücüsü — kombo hattı.
# Çizim -> RecognizerAdapter (shape->rune_id | null) -> ComboStateMachine ->
# ComboResolver -> TEK büyü fırlatılır. Kombo derinleşince dünya yavaşlar
# (Engine.time_scale). Kombo/pencere/overdrive zamanlaması ÖLÇEKLENMEMİŞ gerçek
# zamanla (Time.get_ticks_usec) ölçülür — time_scale'den bağımsız (gereksinim #1).
# İsabet şarjı doldurur -> Overdrive (sağ tık) -> biriken rünler tek büyü.

const HealthScript = preload("res://scripts/health.gd")
const HealthBarScript = preload("res://scripts/health_bar.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

@onready var player: ColorRect = $BattleArea/Player
@onready var enemy: ColorRect = $BattleArea/Enemy
@onready var canvas: ColorRect = $DrawArea/DrawCanvas

const MIN_LEN := 60.0          # geçerli stroke min uzunluk (px)
const PROJ_SPEED := 1400.0     # mermi hızı (px/sn)
const COMMIT_DELAY := 0.22     # düz çizgi/X için ikinci stroke bekleme süresi

# Can / hasar
const PLAYER_MAX_HP := 100

# Düşman dalgası — karışık arketip + farklı zaaf (kombo/zincir/zaaf %40 testi).
# İlk profil sahnedeki Enemy node'unu kullanır; kalanlar koddan spawn edilir.
# weakness: doğru etki tam hasar, yanlış etki %40 (bkz DamageRules).
const ENEMY_PROFILES := [
	{"x": 760.0, "hp": 400, "w": "Burn",    "size": Vector2(150, 300), "col": Color(0.85, 0.35, 0.30, 1), "speed": 45.0, "dmg": 5, "cd": 1.4},
	{"x": 680.0, "hp": 400, "w": "Freeze",  "size": Vector2(150, 300), "col": Color(0.30, 0.55, 0.70, 1), "speed": 45.0, "dmg": 5, "cd": 1.4},
	{"x": 860.0, "hp": 250, "w": "Shatter", "size": Vector2(110, 180), "col": Color(0.80, 0.70, 0.25, 1), "speed": 60.0, "dmg": 4, "cd": 1.2},
	{"x": 940.0, "hp": 150, "w": "Push",    "size": Vector2(90, 120),  "col": Color(0.45, 0.75, 0.45, 1), "speed": 95.0, "dmg": 3, "cd": 1.0},
	{"x": 1010.0,"hp": 150, "w": "Burn",    "size": Vector2(90, 120),  "col": Color(0.80, 0.45, 0.40, 1), "speed": 95.0, "dmg": 3, "cd": 1.0},
]
const GROUND_Y := 992.0

# Etki -> mermi rengi
const EFFECT_COLOR := {
	"Burn": Color(0.9, 0.35, 0.2, 1),
	"Freeze": Color(0.3, 0.7, 0.95, 1),
	"Push": Color(0.35, 0.8, 0.45, 1),
	"Shatter": Color(0.95, 0.85, 0.2, 1),
	"Steam": Color(0.85, 0.85, 0.9, 1),
}
const C_STRIKE := Color(0.9, 0.9, 0.9, 1)

var drawing := false
var casting_active := false     # mid-rün çizim (ilk stroke ile başlar, commit ile biter)
var current: PackedVector2Array = []
var strokes: Array = []
var commit_left := -1.0
var projectiles: Array = []

# Kombo çekirdeği
var db: RuneDB
var recognizer: RecognizerAdapter
var sm: ComboStateMachine
var charge: ChargeMeter
var chain: ChainTracker
var overlay: DebugOverlay
var charge_button: ChargeButton
var trail: RuneTrail
var _last_usec: int = 0

var player_health
var player_bar
var enemies: Array = []   # her giriş: {body, health, bar, ai, weakness}
var game_over := false

func _ready() -> void:
	# Kombo çekirdeği kur
	db = RuneDB.load_from_file()
	recognizer = RecognizerAdapter.new(db)
	sm = ComboStateMachine.new(db, TimeScaleController.new(db))
	charge = ChargeMeter.new(db)
	chain = ChainTracker.new(db)
	overlay = DebugOverlay.new()
	add_child(overlay)
	# Overdrive şarj tuşu — çizim karesinin hemen sağında.
	charge_button = ChargeButton.new()
	charge_button.setup(charge)
	add_child(charge_button)
	var cr := canvas.get_global_rect()
	charge_button.global_position = Vector2(
		cr.position.x + cr.size.x + 40.0,
		cr.position.y + cr.size.y * 0.5 - ChargeButton.H * 0.5)
	charge_button.triggered.connect(_trigger_overdrive)
	_last_usec = Time.get_ticks_usec()

	# Oyuncu
	player_health = _make_health(player, PLAYER_MAX_HP)
	player_bar = _make_bar(player)
	player_health.damaged.connect(_on_player_damaged)
	player_health.died.connect(_on_player_died)

	# Düşman dalgası: ilk profil sahne node'u, kalanlar spawn.
	for i in range(ENEMY_PROFILES.size()):
		var p: Dictionary = ENEMY_PROFILES[i]
		var body: ColorRect = enemy if i == 0 else _spawn_body(p)
		if i == 0:
			body.size = p["size"]
			body.color = p["col"]
		body.position = Vector2(p["x"], GROUND_Y - p["size"].y)
		enemies.append(_make_enemy(body, p))

	# Çizim izi + rün hayaleti — EN SON child (DrawCanvas'ın üstüne çizsin).
	trail = RuneTrail.new()
	add_child(trail)

func _spawn_body(p: Dictionary) -> ColorRect:
	var body := ColorRect.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size = p["size"]
	body.color = p["col"]
	$BattleArea.add_child(body)
	return body

func _make_enemy(body: ColorRect, p: Dictionary) -> Dictionary:
	var health = _make_health(body, p["hp"])
	var bar = _make_bar(body)
	health.damaged.connect(func(_a, _h): bar.set_ratio(health.ratio()))
	var ai = EnemyScript.new()
	ai.move_speed = p["speed"]
	ai.attack_damage = p["dmg"]
	ai.attack_cooldown = p["cd"]
	body.add_child(ai)
	ai.setup(body, player, player_health, health)
	var entry := {"body": body, "health": health, "bar": bar, "ai": ai, "weakness": p["w"]}
	health.died.connect(_on_enemy_died.bind(entry))
	return entry

func _on_player_damaged(_amount: int, _hp: int) -> void:
	player_bar.set_ratio(player_health.ratio())
	chain.on_player_damaged()   # hasar -> zincir sıfır (kombodan bağımsız)

func _make_health(unit: ColorRect, max_hp: int):
	var h = HealthScript.new()
	h.max_hp = max_hp
	unit.add_child(h)
	return h

func _make_bar(unit: ColorRect):
	var bar = HealthBarScript.new()
	add_child(bar)
	_place_bar(bar, unit)
	return bar

func _place_bar(bar, unit: ColorRect) -> void:
	if bar == null or not is_instance_valid(bar) or not is_instance_valid(unit):
		return
	var r := unit.get_global_rect()
	bar.global_position = Vector2(
		r.position.x + r.size.x * 0.5 - HealthBarScript.WIDTH * 0.5,
		r.position.y - HealthBarScript.HEIGHT - 8.0)

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		return
	# Overdrive tetiği: ekrandaki şarj tuşu (asıl) VEYA sağ tık (masaüstü kolaylık).
	# YALNIZ halka doluyken dinlenir.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_trigger_overdrive()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and canvas.get_global_rect().has_point(event.position):
			drawing = true
			commit_left = -1.0
			current = PackedVector2Array([event.position])
			if not casting_active:
				casting_active = true
				sm.on_finger_down()   # pencere donar, casting sınırı başlar
		elif not event.pressed and drawing:
			drawing = false
			if current.size() >= 2:
				strokes.append(current)
			# Tek stroke ve düz değilse X olamaz -> anında commit.
			if strokes.size() == 1 and recognizer.classify_shape(strokes) != "line":
				commit_left = -1.0
				_commit()
			else:
				commit_left = COMMIT_DELAY
	elif event is InputEventMouseMotion and drawing:
		current.append(event.position)

func _process(_delta: float) -> void:
	if game_over:
		return
	# ÖLÇEKLENMEMİŞ dt: duvar saatinden, Engine.time_scale'den bağımsız.
	var now := Time.get_ticks_usec()
	var unscaled_dt := float(now - _last_usec) / 1_000_000.0
	_last_usec = now

	sm.tick(unscaled_dt)
	Engine.time_scale = sm.current_time_scale

	# Casting sınırı doldu: çizimi zorla tamamla (parmakla pause istismarı yok).
	if sm.consume_force_commit() and casting_active:
		if drawing and current.size() >= 2 and (strokes.is_empty() or strokes[strokes.size() - 1] != current):
			strokes.append(current)
		drawing = false
		commit_left = -1.0
		_commit()

	# Overdrive bitince biriken rünler TEK büyü olarak çıkar.
	var od_spell := sm.consume_overdrive_spell()
	if od_spell != null:
		_fire_spell(od_spell)

	# Normal commit zamanlayıcısı (ölçekli delta yerine gerçek dt kullan).
	if commit_left > 0.0:
		commit_left -= unscaled_dt
		if commit_left <= 0.0:
			commit_left = -1.0
			_commit()

	for e in enemies:
		if is_instance_valid(e["body"]) and e["health"].is_alive():
			e["ai"].tick(_delta)   # ölçekli delta (yavaş-mo'da yavaşlar)
			_place_bar(e["bar"], e["body"])
	_advance_projectiles(_delta)

	# Canlı çizim izini güncelle (stroke'lar + aktif current).
	trail.set_live(strokes, current, drawing)

	overlay.update_view(sm, charge, chain)

# --- Can / hasar ---

func _on_enemy_died(entry: Dictionary) -> void:
	chain.on_enemy_death()   # hasar almadan geçen ölüm -> zincir +1
	print("Düşman öldü — kalan %d, zincir %d" % [_alive_count() - 1, chain.count])
	if is_instance_valid(entry["bar"]):
		entry["bar"].queue_free()
	if is_instance_valid(entry["body"]):
		entry["body"].queue_free()

func _alive_count() -> int:
	var n := 0
	for e in enemies:
		if is_instance_valid(e["body"]) and e["health"].is_alive():
			n += 1
	return n

func _on_player_died() -> void:
	game_over = true
	Engine.time_scale = 1.0
	print("Oyun bitti — büyücü öldü")

# Overdrive tetikle — yalnız halka doluyken (dolu değilse girdi yok sayılır).
func _trigger_overdrive() -> void:
	if charge.is_full():
		charge.try_consume()
		sm.start_overdrive()
		print("OVERDRIVE tetiklendi")

# --- Rün commit -> kombo -> büyü ---

func _commit() -> void:
	casting_active = false
	var rid = recognizer.recognize(strokes)   # rune_id VEYA null
	strokes = []
	var spell := sm.on_finger_up(rid)          # null (overdrive) veya çözülmüş büyü
	if spell != null:
		_fire_spell(spell)

# --- Mermi ---

func _fire_spell(spell: ResolvedSpell) -> void:
	var proj := ColorRect.new()
	proj.size = Vector2(48, 22)
	proj.color = _spell_color(spell)
	proj.set_meta("damage", spell.damage)
	proj.set_meta("effects", spell.effects)
	add_child(proj)
	proj.global_position = _player_muzzle() - proj.size * 0.5
	projectiles.append(proj)
	print("Büyü fırlatıldı -> %s" % spell.describe())

func _spell_color(spell: ResolvedSpell) -> Color:
	if spell.effects.is_empty():
		return C_STRIKE
	return EFFECT_COLOR.get(spell.effects[0], C_STRIKE)

func _player_muzzle() -> Vector2:
	var r := player.get_global_rect()
	return Vector2(r.position.x + r.size.x, r.position.y + r.size.y * 0.35)

# Merminin merkezine en yakın CANLI düşman girişi (yoksa null).
func _nearest_enemy(from: Vector2):
	var best = null
	var best_d := INF
	for e in enemies:
		if not is_instance_valid(e["body"]) or not e["health"].is_alive():
			continue
		var c: Vector2 = e["body"].get_global_rect().get_center()
		var d := from.distance_to(c)
		if d < best_d:
			best_d = d
			best = e
	return best

func _advance_projectiles(delta: float) -> void:
	if projectiles.is_empty():
		return
	# Hiç canlı düşman yok: uçan mermileri temizle (freed node'a nişan alma).
	if _alive_count() == 0:
		for proj in projectiles:
			proj.queue_free()
		projectiles = []
		return
	for proj in projectiles.duplicate():
		var center: Vector2 = proj.global_position + proj.size * 0.5
		var target = _nearest_enemy(center)
		if target == null:
			continue
		var tc: Vector2 = target["body"].get_global_rect().get_center()
		var to := tc - center
		if to.length() <= PROJ_SPEED * delta + 4.0:
			var base_dmg: int = proj.get_meta("damage", 0)
			var effects: Array = proj.get_meta("effects", [])
			# Zaaf: yanlış etki %40, sıfır değil (bkz DamageRules). Hedefin kendi zaafı.
			var dmg := DamageRules.apply_weakness(base_dmg, effects, target["weakness"], db)
			target["health"].take_damage(dmg)
			charge.add_hit()   # ŞARJ isabetten dolar (öldürmeden değil)
			print("İsabet (zaaf %s) -> %d hasar (kalan %d) | şarj %d%%" % [
				target["weakness"], dmg, target["health"].hp, int(round(charge.ratio() * 100.0))])
			projectiles.erase(proj)
			proj.queue_free()
		else:
			proj.global_position += to.normalized() * PROJ_SPEED * delta
