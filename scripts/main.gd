extends Node2D

# Rün tanıma + mermi. DrawCanvas'a çizilen stroke(lar) sınıflandırılır:
#   düz çizgi -> temel düz vuruş (beyaz)
#   X  (kesişen iki çizgi)      -> kırmızı mermi
#   O  (kapalı halka)           -> camgöbeği mermi
#   Yıldırım (zigzag, çok köşe) -> sarı mermi
#   V  (tek keskin köşe)        -> yeşil mermi
# Her rün Player'dan Enemy'ye mermi gönderir. Hasar/can yok; logic + renk.

const HealthScript = preload("res://scripts/health.gd")
const HealthBarScript = preload("res://scripts/health_bar.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

@onready var player: ColorRect = $BattleArea/Player
@onready var enemy: ColorRect = $BattleArea/Enemy
@onready var canvas: ColorRect = $DrawArea/DrawCanvas

const MIN_LEN := 60.0          # geçerli stroke min uzunluk (px)
const PROJ_SPEED := 1400.0     # mermi hızı (px/sn)
const COMMIT_DELAY := 0.22     # düz çizgi/X için ikinci stroke bekleme süresi
const CORNER_DEG := 55.0       # köşe sayılacak min dönüş açısı
const CLOSED_RATIO := 0.30     # kapalı şekil: baş-son mesafe / yol uzunluğu eşiği

# Can / hasar
const PLAYER_MAX_HP := 100
const ENEMY_MAX_HP := 400   # tank: bol HP, öldürmesi zor (~13-40 rün vuruşu)
# Rüne göre mermi hasarı
const RUNE_DAMAGE := {"line": 10, "X": 25, "O": 15, "lightning": 30, "V": 20}

# Rün renkleri
const C_LINE := Color(0.9, 0.9, 0.9, 1)     # düz vuruş
const C_X := Color(0.9, 0.25, 0.25, 1)      # X
const C_O := Color(0.3, 0.7, 0.95, 1)       # O
const C_LIGHT := Color(0.95, 0.85, 0.2, 1)  # Yıldırım
const C_V := Color(0.35, 0.8, 0.45, 1)      # V

var drawing := false
var current: PackedVector2Array = []
var strokes: Array = []
var commit_left := -1.0
var projectiles: Array = []

var player_health
var enemy_health
var player_bar
var enemy_bar
var enemy_ai
var game_over := false

func _ready() -> void:
	player_health = _make_health(player, PLAYER_MAX_HP)
	enemy_health = _make_health(enemy, ENEMY_MAX_HP)
	player_bar = _make_bar(player)
	enemy_bar = _make_bar(enemy)
	player_health.damaged.connect(func(_a, _h): player_bar.set_ratio(player_health.ratio()))
	enemy_health.damaged.connect(func(_a, _h): enemy_bar.set_ratio(enemy_health.ratio()))
	player_health.died.connect(_on_player_died)
	enemy_health.died.connect(_on_enemy_died)
	# Tank düşman: yürür + menzilde melee vurur. Stat'lar enemy.gd @export
	# varsayılanları (yavaş hız / düşük hasar); HP yukarıda ENEMY_MAX_HP.
	enemy_ai = EnemyScript.new()
	enemy.add_child(enemy_ai)
	enemy_ai.setup(enemy, player, player_health, enemy_health)
	enemy_ai.attacked.connect(func(dmg): print("Tank vurdu -> %d hasar (oyuncu kalan %d)" % [dmg, player_health.hp]))

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

# Çubuğu birimin tam üstüne ortalar (birim hareket edince her frame çağrılır).
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and canvas.get_global_rect().has_point(event.position):
			drawing = true
			commit_left = -1.0
			current = PackedVector2Array([event.position])
		elif not event.pressed and drawing:
			drawing = false
			if current.size() >= 2:
				strokes.append(current)
			# Erken commit: tek stroke ve düz değilse X olamaz -> anında tetikle.
			# Sadece düz çizgi (X'in ilk yarısı olabilir) ikinci stroke için bekler.
			if strokes.size() == 1 and _classify(strokes) != "line":
				commit_left = -1.0
				_commit()
			else:
				commit_left = COMMIT_DELAY
	elif event is InputEventMouseMotion and drawing:
		current.append(event.position)

func _process(delta: float) -> void:
	if game_over:
		return
	if commit_left > 0.0:
		commit_left -= delta
		if commit_left <= 0.0:
			commit_left = -1.0
			_commit()
	if enemy_ai != null and is_instance_valid(enemy):
		enemy_ai.tick(delta)
		_place_bar(enemy_bar, enemy)  # tank yürüdükçe can çubuğu takip etsin
	_advance_projectiles(delta)

# --- Can / hasar ---

func _on_enemy_died() -> void:
	print("Düşman öldü")
	enemy_bar.queue_free()
	enemy.queue_free()

func _on_player_died() -> void:
	game_over = true
	print("Oyun bitti — büyücü öldü")

# --- Rün sınıflandırma ---

func _commit() -> void:
	if strokes.is_empty():
		return
	var rune := _classify(strokes)
	strokes = []
	match rune:
		"line":
			print("Düz çizgi -> düz vuruş")
			_fire(C_LINE, RUNE_DAMAGE["line"])
		"X":
			print("X rünü")
			_fire(C_X, RUNE_DAMAGE["X"])
		"O":
			print("O rünü")
			_fire(C_O, RUNE_DAMAGE["O"])
		"lightning":
			print("Yıldırım rünü")
			_fire(C_LIGHT, RUNE_DAMAGE["lightning"])
		"V":
			print("V rünü")
			_fire(C_V, RUNE_DAMAGE["V"])
		_:
			print("Rün tanınmadı, vuruş yok")

func _classify(all_strokes: Array) -> String:
	if all_strokes.size() >= 2 and _strokes_cross(all_strokes):
		return "X"
	var s: PackedVector2Array = all_strokes[0]
	var rs := _resample(s, 24)
	var plen := _path_len(rs)
	if plen < MIN_LEN:
		return "none"
	if rs[0].distance_to(rs[rs.size() - 1]) / plen < CLOSED_RATIO:
		return "O"
	var corners := _count_corners(rs)
	if corners == 0:
		return "line"
	elif corners == 1:
		return "V"
	else:
		return "lightning"

func _strokes_cross(all_strokes: Array) -> bool:
	for i in range(all_strokes.size()):
		for j in range(i + 1, all_strokes.size()):
			var a := _resample(all_strokes[i], 16)
			var b := _resample(all_strokes[j], 16)
			for m in range(a.size() - 1):
				for n in range(b.size() - 1):
					if Geometry2D.segment_intersects_segment(a[m], a[m + 1], b[n], b[n + 1]) != null:
						return true
	return false

func _count_corners(pts: PackedVector2Array) -> int:
	var count := 0
	var thresh := deg_to_rad(CORNER_DEG)
	var i := 1
	while i < pts.size() - 1:
		var v1 := pts[i] - pts[i - 1]
		var v2 := pts[i + 1] - pts[i]
		if v1.length() > 0.0 and v2.length() > 0.0 and abs(v1.angle_to(v2)) > thresh:
			count += 1
			i += 2  # aynı köşeyi iki kez sayma
		else:
			i += 1
	return count

func _path_len(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	return total

func _resample(pts: PackedVector2Array, n: int) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var plen := _path_len(pts)
	if plen <= 0.0:
		return pts
	var interval := plen / float(n - 1)
	var out := PackedVector2Array([pts[0]])
	var acc := 0.0
	var prev := pts[0]
	var i := 1
	while i < pts.size():
		var cur := pts[i]
		var d := prev.distance_to(cur)
		if acc + d >= interval and d > 0.0:
			var t := (interval - acc) / d
			var q := prev.lerp(cur, t)
			out.append(q)
			prev = q
			acc = 0.0
		else:
			acc += d
			prev = cur
			i += 1
	while out.size() < n:
		out.append(pts[pts.size() - 1])
	return out

# --- Mermi ---

func _fire(color: Color, damage: int) -> void:
	var proj := ColorRect.new()
	proj.size = Vector2(48, 22)
	proj.color = color
	proj.set_meta("damage", damage)
	add_child(proj)
	proj.global_position = _player_muzzle() - proj.size * 0.5
	projectiles.append(proj)

func _player_muzzle() -> Vector2:
	var r := player.get_global_rect()
	return Vector2(r.position.x + r.size.x, r.position.y + r.size.y * 0.35)

func _enemy_center() -> Vector2:
	var r := enemy.get_global_rect()
	return r.position + r.size * 0.5

func _advance_projectiles(delta: float) -> void:
	if projectiles.is_empty():
		return
	# Hedef öldü/yok: uçan mermileri temizle (freed node'a nişan alıp çökme).
	if not is_instance_valid(enemy) or not enemy_health.is_alive():
		for proj in projectiles:
			proj.queue_free()
		projectiles = []
		return
	var target := _enemy_center()
	for proj in projectiles.duplicate():
		var center: Vector2 = proj.global_position + proj.size * 0.5
		var to := target - center
		if to.length() <= PROJ_SPEED * delta + 4.0:
			var dmg: int = proj.get_meta("damage", 0)
			enemy_health.take_damage(dmg)
			print("Mermi isabet -> %d hasar (düşman kalan %d)" % [dmg, enemy_health.hp])
			projectiles.erase(proj)
			proj.queue_free()
		else:
			proj.global_position += to.normalized() * PROJ_SPEED * delta
