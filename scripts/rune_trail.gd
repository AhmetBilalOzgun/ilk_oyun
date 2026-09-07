extends Node2D
class_name RuneTrail

# Çizim geri bildirimi — canlı iz: parmak çizerken stroke'ların arkasında parlak bir
# hat + uç noktası. "Ben yaptım" hissini güçlendirir.
# Ana sahnenin (Node2D, origin=0) EN SON child'ı olarak eklenir; böylece DrawCanvas
# ColorRect'inin ÜSTÜNE çizer. Koordinatlar global == main-local == trail-local.

const TRAIL_COLOR := Color(0.6, 0.85, 1.0, 0.95)
const TRAIL_WIDTH := 6.0

var live_strokes: Array = []
var live_current: PackedVector2Array = []
var drawing := false

# Ana sahne her frame canlı durumu buraya iter.
func set_live(strokes: Array, current: PackedVector2Array, is_drawing: bool) -> void:
	live_strokes = strokes
	live_current = current
	drawing = is_drawing
	queue_redraw()

func _draw() -> void:
	if not (drawing or not live_strokes.is_empty()):
		return
	for st in live_strokes:
		if st.size() >= 2:
			draw_polyline(st, TRAIL_COLOR, TRAIL_WIDTH, true)
	if live_current.size() >= 2:
		draw_polyline(live_current, TRAIL_COLOR, TRAIL_WIDTH, true)
	if live_current.size() >= 1:
		draw_circle(live_current[live_current.size() - 1], TRAIL_WIDTH * 0.65, TRAIL_COLOR)
