extends Node2D
class_name QteMinigame

# QTE çizim minigame'i — ekranın ORTASINDA. İki katman:
#   1) KILAVUZ: hedef rünün soluk şablonu (oyuncu parmakla takip etsin).
#   2) İZ: oyuncu çizdikçe eleman renginde canlı hat (girdi görünür olsun ->
#      "renk kazanır"). Doğru takip = şablonun renklenmesi hissi.
# Tam ekran Node2D (origin 0) — RuneTrail deseni: her şey global koordinatta çizilir,
# böylece battle.gd global stroke'ları olduğu gibi verir. Eski RuneTrail'e dokunmaz.

const GUIDE_COLOR := Color(1, 1, 1, 0.22)
const GUIDE_WIDTH := 14.0
const TRAIL_WIDTH := 9.0
const PANEL_COLOR := Color(0.10, 0.10, 0.14, 0.92)
const PAD := 0.16   # kılavuz kenar boşluğu (kutu oranı)

# Rün şablonları — birim koordinat (0..1), kutuya ölçeklenir. Şekiller
# RecognizerAdapter sınıflandırmasıyla uyumlu (shape_to_rune):
#   ember=X, frost=O, gale=şimşek, storm=V. Birleşim becerileri yeni şekil
#   getirmez; kaynak rünleri (ör. ember->storm) peş peşe gösterir.
const GUIDES := {
	"ember":  [[Vector2(0.2, 0.2), Vector2(0.8, 0.8)], [Vector2(0.8, 0.2), Vector2(0.2, 0.8)]],
	"gale":   [[Vector2(0.22, 0.25), Vector2(0.5, 0.45), Vector2(0.32, 0.58), Vector2(0.78, 0.8)]],
	"storm":  [[Vector2(0.25, 0.2), Vector2(0.5, 0.82), Vector2(0.75, 0.2)]],
	# frost=O runtime'da _circle() ile üretilir (aşağıda).
}

var rect: Rect2 = Rect2(260, 680, 560, 560)
var rune_id: String = ""
var trail_color: Color = Color(0.6, 0.85, 1.0, 0.95)

var live_strokes: Array = []
var live_current: PackedVector2Array = []
var drawing := false
var _active := false

func setup(p_rune_id: String, p_color: Color, p_rect: Rect2) -> void:
	rune_id = p_rune_id
	trail_color = p_color
	rect = p_rect
	_active = true
	live_strokes = []
	live_current = PackedVector2Array()
	drawing = false
	visible = true
	queue_redraw()

func hide_game() -> void:
	_active = false
	visible = false
	queue_redraw()

func set_live(strokes: Array, current: PackedVector2Array, is_drawing: bool) -> void:
	live_strokes = strokes
	live_current = current
	drawing = is_drawing
	queue_redraw()

# Birim (0..1) -> kutu içi global nokta (PAD boşluklu).
func _map(u: Vector2) -> Vector2:
	var inner := rect.grow(-rect.size.x * PAD)
	return inner.position + Vector2(u.x * inner.size.x, u.y * inner.size.y)

func _guide_strokes() -> Array:
	if rune_id == "frost":
		return [_circle(Vector2(0.5, 0.5), 0.3, 28)]
	return GUIDES.get(rune_id, [])

func _circle(center: Vector2, r: float, n: int) -> Array:
	var pts: Array = []
	for i in range(n + 1):
		var a := TAU * float(i) / float(n)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts

func _draw() -> void:
	if not _active:
		return
	# Panel arka planı (çizim alanı belli olsun).
	draw_rect(rect, PANEL_COLOR, true)
	draw_rect(rect, Color(1, 1, 1, 0.15), false, 3.0)

	# Kılavuz şablon (soluk) + başlangıç noktası işareti.
	for st in _guide_strokes():
		var poly := PackedVector2Array()
		for u in st:
			poly.append(_map(u))
		if poly.size() >= 2:
			draw_polyline(poly, GUIDE_COLOR, GUIDE_WIDTH, true)
			draw_circle(poly[0], GUIDE_WIDTH * 0.9, Color(0.5, 0.9, 0.5, 0.5))  # başla burdan

	# Oyuncunun canlı izi (eleman renginde) — girdi görünür.
	for st in live_strokes:
		if st.size() >= 2:
			draw_polyline(st, trail_color, TRAIL_WIDTH, true)
	if live_current.size() >= 2:
		draw_polyline(live_current, trail_color, TRAIL_WIDTH, true)
	if live_current.size() >= 1:
		draw_circle(live_current[live_current.size() - 1], TRAIL_WIDTH * 0.7, trail_color)
