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

# Can / hasar
const PLAYER_MAX_HP := 100

# Düşman arketipleri — sabit temel istatistik. Dalga tanımı bunlara ADLA atıfta
# bulunur (bkz WAVES). weakness (w): doğru etki tam hasar, yanlış etki %40 (DamageRules).
#   tank   : yüksek HP, düşük hasar, yavaş — melee. Öldürmesi zor, tehlike yavaş.
#   swarm  : düşük HP, hızlı, sürü — melee. Tek tek zayıf, kalabalıkla ezer.
#   archer : orta HP — RANGED. Menzilde durur, mermi atar (bkz enemy.is_ranged).
const ENEMY_TYPES := {
	"tank":   {"hp": 400, "w": "Burn",   "size": Vector2(150, 300), "col": Color(0.85, 0.35, 0.30, 1), "speed": 45.0,  "dmg": 5, "cd": 1.4, "ranged": false},
	"swarm":  {"hp": 60,  "w": "Push",   "size": Vector2(55, 90),   "col": Color(0.55, 0.75, 0.40, 1), "speed": 120.0, "dmg": 2, "cd": 0.8, "ranged": false},
	"archer": {"hp": 120, "w": "Freeze", "size": Vector2(80, 150),  "col": Color(0.80, 0.70, 0.25, 1), "speed": 70.0,  "dmg": 4, "cd": 1.6, "ranged": true, "range": 360.0},
}

# Dalgalar sırayla gelir: bir dalga tamamen temizlenince sonraki spawn olur.
# Her giriş [tür, adet]. Son dalga bitince oyun kazanılır.
const WAVES := [
	[["tank", 1], ["swarm", 10]],                  # Dalga 1
	[["tank", 3], ["archer", 2]],                  # Dalga 2
	[["tank", 2], ["archer", 2], ["swarm", 5]],    # Dalga 3 (son)
]

const GROUND_Y := 992.0
const ENEMY_PROJ_SPEED := 650.0   # okçu mermisi hızı (px/sn)
# Düşmanlar bu x bandına yayılarak spawn olur (oyuncu solda ~150).
const SPAWN_X_MIN := 520.0
const SPAWN_X_MAX := 1040.0

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
var enemies: Array = []           # her giriş: {body, health, bar, ai, weakness}
var enemy_projectiles: Array = [] # okçu mermileri (oyuncuya doğru)
var current_wave := -1            # aktif dalga indeksi (spawn öncesi -1)
var game_over := false
var game_won := false

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

	# Sahnedeki tekil Enemy node artık kullanılmıyor — tüm düşmanlar dalga dalga
	# koddan spawn edilir. Node'u temizle (yoksa boş kutu ekranda kalır).
	if is_instance_valid(enemy):
		enemy.queue_free()

	# Çizim izi + rün hayaleti — EN SON child (DrawCanvas'ın üstüne çizsin).
	trail = RuneTrail.new()
	add_child(trail)

	# İlk dalgayı başlat.
	_advance_wave()

# --- Dalga sistemi ---

# Sonraki dalgaya geç: son dalga geçildiyse oyunu kazan, değilse spawn et.
func _advance_wave() -> void:
	current_wave += 1
	if current_wave >= WAVES.size():
		_on_all_waves_cleared()
		return
	_spawn_wave(current_wave)
	print("Dalga %d/%d başladı — %d düşman" % [
		current_wave + 1, WAVES.size(), _alive_count()])

# Dalga tanımını [tür, adet] listelerinden açar, x bandına yayarak spawn eder.
func _spawn_wave(index: int) -> void:
	var types: Array = []
	for pair in WAVES[index]:
		for _i in range(int(pair[1])):
			types.append(pair[0])
	var n := types.size()
	for i in range(n):
		var p: Dictionary = (ENEMY_TYPES[types[i]] as Dictionary).duplicate()
		var x := (SPAWN_X_MIN + SPAWN_X_MAX) * 0.5
		if n > 1:
			x = SPAWN_X_MIN + (SPAWN_X_MAX - SPAWN_X_MIN) * float(i) / float(n - 1)
		var body := _spawn_body(p)
		body.position = Vector2(x, GROUND_Y - p["size"].y)
		enemies.append(_make_enemy(body, p))

func _on_all_waves_cleared() -> void:
	game_won = true
	game_over = true
	Engine.time_scale = 1.0
	print("Tüm dalgalar temizlendi — ZAFER")

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
	if p.get("ranged", false):
		ai.is_ranged = true
		ai.attack_range = p.get("range", 360.0)
		ai.fired.connect(_on_enemy_fired)
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
			current = PackedVector2Array([event.position])
			if not casting_active:
				casting_active = true
				sm.on_finger_down()   # pencere donar, casting sınırı başlar
		elif not event.pressed and drawing:
			drawing = false
			if current.size() >= 2:
				strokes.append(current)
			# Parmak kalktı -> bekleme YOK, anında commit.
			# Hareketsiz/kısa stroke -> tanıma "none" -> null -> strike (düz vuruş=tık).
			_commit()
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
		_commit()

	# Overdrive bitince biriken rünler TEK büyü olarak çıkar.
	var od_spell := sm.consume_overdrive_spell()
	if od_spell != null:
		_fire_spell(od_spell)

	for e in enemies:
		if is_instance_valid(e["body"]) and e["health"].is_alive():
			e["ai"].tick(_delta)   # ölçekli delta (yavaş-mo'da yavaşlar)
			_place_bar(e["bar"], e["body"])
	_advance_projectiles(_delta)
	_advance_enemy_projectiles(_delta)

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
	# Dalga temizlendi mi? (ölen düşman zaten is_alive()==false, sayımdan düştü.)
	if not game_over and _alive_count() == 0:
		_advance_wave()

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

# --- Okçu mermileri (düşman -> oyuncu) ---

# enemy.gd ranged saldırısı bunu tetikler: namludan oyuncuya bir mermi doğar.
func _on_enemy_fired(from: Vector2, damage: int) -> void:
	if game_over:
		return
	var proj := ColorRect.new()
	proj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	proj.size = Vector2(26, 10)
	proj.color = Color(0.9, 0.5, 0.25, 1)
	proj.set_meta("damage", damage)
	add_child(proj)
	proj.global_position = from - proj.size * 0.5
	enemy_projectiles.append(proj)

func _advance_enemy_projectiles(delta: float) -> void:
	if enemy_projectiles.is_empty():
		return
	var pc := player.get_global_rect().get_center()
	for proj in enemy_projectiles.duplicate():
		var center: Vector2 = proj.global_position + proj.size * 0.5
		var to := pc - center
		if to.length() <= ENEMY_PROJ_SPEED * delta + 6.0:
			if player_health != null and player_health.is_alive():
				player_health.take_damage(proj.get_meta("damage", 0))
			enemy_projectiles.erase(proj)
			proj.queue_free()
		else:
			proj.global_position += to.normalized() * ENEMY_PROJ_SPEED * delta
