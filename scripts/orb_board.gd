extends Node2D
class_name OrbBoard

# Top-çoğaltma board'u. CHOICE düğümünde açılır: oyuncu yendiği düşman başına 1 orb
# kazanır, üstten DOKUN-BIRAK ile döker. Orb'lar SEYREK peg alanından süzülürken
# ekrandaki yatay ÇARPAN ÇİZGİLERİNden (gate) geçebilir — bir çizgiden geçen orb
# SAYICA çoğalır (x2 -> 1 klon, x3 -> 2 klon). Dipteki huni tüm orb'ları toplayıcıya
# yönlendirir. DRAFT PUANI = toplanan orb sayısı × ORB_VALUE.
#
# Tasarım kararları (kullanıcı isteği):
#   * NEGATİF / <1 çarpan YOK — sadece top artıran çizgiler.
#   * Çarpan artık NOKTA değil, ekran boyu YATAY ÇİZGİ (aim -> strateji).
#   * Peg sayısı AZ — savrulma (şans) düşük, nişan alma (strateji) yüksek.
#   * Çarpandan geçince PUAN değil TOP SAYISI çarpılır (2x -> 2 katı top).
#
# Koddan kurulur (.tscn yok). Fizik: RigidBody2D orb + StaticBody2D peg/duvar/huni.
# Çarpan çizgileri Area2D (orb'u DURDURMAZ, sadece geçişi yakalar). GUI Control'ler
# tıklamayı yemesin diye girdi `_input`'ta okunur ve tüm Control'ler MOUSE_FILTER_IGNORE.

signal finished(points)

const ORB_R := 20.0
const PEG_R := 10.0
const SETTLE_TIMEOUT := 8.0
const MAX_ORBS := 90          # patlama koruması (çoğalma üst sınırı)
const ORB_VALUE := OrbBoardResult.ORB_VALUE
const PIXEL_FONT = preload("res://assets/fonts/PixelifySans-Bold.ttf")

var _rect: Rect2
var _to_drop := 0             # başlangıçta dökülecek orb sayısı (düşman başına 1)
var _dropped := 0             # dökülen başlangıç orb'u
var _alive := 0               # sahnedeki canlı orb (klonlar dahil)
var _collected := 0           # toplayıcıya ulaşan orb (puan buradan)
var _finished := false
var _settle := -1.0
var _hud: Label
var _drop_y: float

func setup(orb_count: int, rect: Rect2) -> void:
	_rect = rect
	_to_drop = orb_count
	_drop_y = rect.position.y + 40.0
	_build_frame()
	_build_pegs()
	_build_gates()
	_build_funnel()
	_build_hud()

# --- Kurulum ---

func _build_frame() -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.07, 0.16, 0.92)
	panel.position = _rect.position
	panel.size = _rect.size
	panel.z_index = -2
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	# Dış piksel çerçeve
	var frame := ReferenceRect.new()
	frame.position = _rect.position
	frame.size = _rect.size
	frame.border_color = Color(0.9, 0.75, 0.3, 0.8)
	frame.border_width = 4.0
	frame.editor_only = false
	frame.z_index = -1
	add_child(frame)

	var t := 16.0
	_wall_rect(Rect2(_rect.position.x - t, _rect.position.y, t, _rect.size.y))   # sol
	_wall_rect(Rect2(_rect.end.x, _rect.position.y, t, _rect.size.y))            # sağ

func _wall_rect(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = r.position + r.size * 0.5
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	col.shape = shape
	body.add_child(col)
	add_child(body)

# İki nokta arası doğrusal duvar (huni kenarı).
func _wall_segment(a: Vector2, b: Vector2) -> void:
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := SegmentShape2D.new()
	shape.a = a
	shape.b = b
	col.shape = shape
	body.add_child(col)
	add_child(body)
	var line := Line2D.new()
	line.points = PackedVector2Array([a, b])
	line.width = 6.0
	line.default_color = Color(0.55, 0.6, 0.8)
	add_child(line)

# SEYREK peg ızgarası — sadece hafif savrulma. Az nokta = strateji > şans.
func _build_pegs() -> void:
	var rows := 3
	var top := _rect.position.y + 200.0
	var bottom := _rect.position.y + _rect.size.y * 0.55
	var row_gap := (bottom - top) / float(rows)
	for row in range(rows):
		var y := top + row * row_gap
		var cols := 4 if row % 2 == 0 else 3
		var span := _rect.size.x - 160.0
		var gap := span / float(cols)
		var x0 := _rect.position.x + 80.0 + (gap * 0.5 if row % 2 == 1 else 0.0)
		for c in range(cols):
			_peg(Vector2(x0 + c * gap, y))

func _peg(pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = PEG_R
	col.shape = shape
	body.add_child(col)
	body.add_child(_circle(PEG_R, Color(0.7, 0.75, 0.9)))
	add_child(body)

# Yatay çarpan çizgileri (top çoğaltıcı). HER TUR RASTGELE DİZİLİR.
func _build_gates() -> void:
	var mult_pool := [2, 3, 4, 2, 3, 2]
	mult_pool.shuffle()
	
	var active_gates := [
		{"y_frac": 0.38, "x_frac": randf_range(0.08, 0.16), "w_frac": 0.34, "mult": mult_pool[0]},
		{"y_frac": 0.38, "x_frac": randf_range(0.54, 0.62), "w_frac": 0.34, "mult": mult_pool[1]},
		{"y_frac": 0.60, "x_frac": randf_range(0.28, 0.38), "w_frac": 0.38, "mult": mult_pool[2]},
	]

	for i in range(active_gates.size()):
		var g: Dictionary = active_gates[i]
		var w: float = _rect.size.x * float(g["w_frac"])
		var cx: float = _rect.position.x + _rect.size.x * float(g["x_frac"]) + w * 0.5
		var cy: float = _rect.position.y + _rect.size.y * float(g["y_frac"])
		var m: int = g["mult"]
		var area := Area2D.new()
		area.position = Vector2(cx, cy)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(w, 16.0)
		col.shape = shape
		area.add_child(col)
		area.body_entered.connect(_on_gate_hit.bind(i, m))
		add_child(area)
		
		# Görsel: parlak çizgi + piksel font "x2" etiketi.
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(-w * 0.5, 0.0), Vector2(w * 0.5, 0.0)])
		line.width = 12.0
		line.default_color = _mult_color(m)
		line.position = Vector2(cx, cy)
		add_child(line)

		var lbl := Label.new()
		lbl.text = "x%d" % m
		lbl.position = Vector2(cx - 24.0, cy - 24.0)
		lbl.add_theme_font_override("font", PIXEL_FONT)
		lbl.add_theme_font_size_override("font_size", 34)
		lbl.add_theme_constant_override("outline_size", 6)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		lbl.add_theme_color_override("font_color", _mult_color(m))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)

# Dip huni: iki eğik kenar orta boşluğa yönlendirir; boşluğun altında toplayıcı.
func _build_funnel() -> void:
	var y_top := _rect.position.y + _rect.size.y * 0.72
	var y_gap := _rect.end.y - 120.0
	var cx := _rect.position.x + _rect.size.x * 0.5
	var half_gap := 80.0
	_wall_segment(Vector2(_rect.position.x, y_top), Vector2(cx - half_gap, y_gap))
	_wall_segment(Vector2(_rect.end.x, y_top), Vector2(cx + half_gap, y_gap))
	# Toplayıcı: boşluğun altında, tüm orb'ları yutar (collected++).
	var col_area := Area2D.new()
	col_area.position = Vector2(cx, _rect.end.y - 40.0)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(half_gap * 2.0 + 40.0, 60.0)
	col.shape = shape
	col_area.add_child(col)
	col_area.body_entered.connect(_on_collected)
	add_child(col_area)
	var vis := ColorRect.new()
	vis.size = Vector2(half_gap * 2.0 + 40.0, 36.0)
	vis.position = Vector2(cx - half_gap - 20.0, _rect.end.y - 58.0)
	vis.color = Color(0.2, 0.85, 0.5, 0.85)
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vis)

	var lbl := Label.new()
	lbl.text = "TOPLAYICI"
	lbl.position = Vector2(cx - 56.0, _rect.end.y - 50.0)
	lbl.add_theme_font_override("font", PIXEL_FONT)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.05, 0.15, 0.08))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

func _build_hud() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(_rect.size.x, 48.0)
	bg.position = Vector2(_rect.position.x, _rect.position.y - 58.0)
	bg.color = Color(0.08, 0.07, 0.16, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_hud = Label.new()
	_hud.position = Vector2(_rect.position.x + 12.0, _rect.position.y - 48.0)
	_hud.add_theme_font_override("font", PIXEL_FONT)
	_hud.add_theme_font_size_override("font_size", 26)
	_hud.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)
	_update_hud()

func _update_hud() -> void:
	if _hud != null:
		_hud.text = "ORB DÖK — kalan %d/%d   toplanan %d   puan %d   (üste dokun)" % [
			_to_drop - _dropped, _to_drop, _collected, _collected * ORB_VALUE]

# --- Girdi: dokun-bırak (GUI yemesin diye _input) ---

func _input(event: InputEvent) -> void:
	if _finished or _dropped >= _to_drop:
		return
	var pos := Vector2.ZERO
	var tapped := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pos = event.position
		tapped = true
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
		tapped = true
	if tapped and _rect.has_point(pos):
		_dropped += 1
		_spawn_orb(Vector2(clampf(pos.x, _rect.position.x + 40.0, _rect.end.x - 40.0), _drop_y), {})
		_update_hud()

# Bir orb yarat. gates: bu orb'un zaten kullandığı çarpan çizgileri (klon zinciri
# aynı çizgiden tekrar tetiklenmesin -> patlama koruması).
func _spawn_orb(pos: Vector2, gates: Dictionary, impulse := Vector2.ZERO) -> void:
	if _alive >= MAX_ORBS:
		return
	var orb := RigidBody2D.new()
	orb.position = pos
	orb.gravity_scale = 1.0
	orb.set_meta("gates", gates.duplicate())
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.3
	pm.friction = 0.15
	orb.physics_material_override = pm
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = ORB_R
	col.shape = shape
	orb.add_child(col)
	orb.add_child(_circle(ORB_R, Color(1.0, 0.82, 0.25)))
	add_child(orb)
	if impulse != Vector2.ZERO:
		orb.linear_velocity = impulse
	_alive += 1

# Çarpan çizgisi: orb bu çizgiyi ilk kez geçiyorsa (mult-1) klon üret -> top çoğalır.
func _on_gate_hit(body: Node, gate_idx: int, mult: int) -> void:
	if _finished or not (body is RigidBody2D):
		return
	var gates: Dictionary = body.get_meta("gates", {})
	if gates.has(gate_idx):
		return   # bu orb bu çizgiyi zaten kullandı
	gates[gate_idx] = true
	body.set_meta("gates", gates)
	# Klonlar aynı çizgiyi tekrar tetiklemesin diye gate geçmişini paylaşırlar.
	var pos: Vector2 = (body as Node2D).global_position
	var vel: Vector2 = (body as RigidBody2D).linear_velocity
	for k in range(mult - 1):
		var nudge := Vector2(randf_range(-140.0, 140.0), -abs(vel.y) * 0.2 - 60.0)
		_spawn_orb.call_deferred(pos + Vector2(randf_range(-6.0, 6.0), 0.0), gates, vel + nudge)
	_update_hud()

func _on_collected(body: Node) -> void:
	if _finished or not (body is RigidBody2D):
		return
	if body.get_meta("done", false):
		return
	body.set_meta("done", true)
	_collected += 1
	_alive -= 1
	(body as Node).queue_free()
	_update_hud()
	_maybe_finish()

func _process(delta: float) -> void:
	if _finished:
		return
	# Tüm başlangıç orb'u döküldü ama sahnede canlı orb takıldıysa: timeout -> bitir.
	if _dropped >= _to_drop and _alive > 0:
		if _settle < 0.0:
			_settle = SETTLE_TIMEOUT
		_settle -= delta
		if _settle <= 0.0:
			_finish()

func _maybe_finish() -> void:
	if _dropped >= _to_drop and _alive <= 0:
		_finish()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	# Puan = toplanan orb × ORB_VALUE (her orb 1.0 çarpan).
	var mults: Array = []
	mults.resize(_collected)
	mults.fill(1.0)
	finished.emit(OrbBoardResult.score(mults))

# --- Görsel yardımcı ---

func _circle(r: float, col: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	var seg := 20
	for i in range(seg):
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * r)
	poly.polygon = pts
	poly.color = col
	return poly

func _mult_color(m: int) -> Color:
	if m >= 3:
		return Color(0.97, 0.55, 0.25)   # x3 turuncu
	return Color(0.4, 0.85, 0.7)         # x2 yeşil-mavi
