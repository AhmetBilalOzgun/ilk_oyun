extends IRuneRecognizer
class_name RecognizerAdapter

# Motor tarafı rün tanıyıcı. Çizim geometrisi burada (main.gd'den taşındı).
# classify_shape(strokes) -> "line"/"X"/"O"/"lightning"/"V"/"none"
# recognize(strokes) -> rune_id (db.shape_to_rune ile) VEYA null.
# "none" veya haritada yoksa -> null -> çağıran strike'a düşer.
#
# shape -> rune eşlemesi config'te (shape_to_rune). Çekirdek state machine
# geometriyi bilmez; sonuç (rune_id | null) ona verilir.

const MIN_LEN := 60.0          # geçerli stroke min uzunluk (px)
const CORNER_DEG := 55.0       # köşe sayılacak min dönüş açısı
const CLOSED_RATIO := 0.30     # kapalı şekil: baş-son mesafe / yol uzunluğu eşiği

var _db: RuneDB

func _init(db: RuneDB) -> void:
	_db = db

func recognize(strokes) -> Variant:
	var shape := classify_shape(strokes)
	if shape == "none":
		return null
	var rid = _db.shape_to_rune.get(shape, null)
	if rid == null or not _db.has_rune(rid):
		return null
	return rid

# --- Geometri (main.gd'den taşındı) ---

func classify_shape(all_strokes: Array) -> String:
	if all_strokes.is_empty():
		return "none"
	if all_strokes.size() >= 2 and _strokes_cross(all_strokes):
		return "X"
	var s: PackedVector2Array = all_strokes[0]
	var rs := _resample(s, 24)
	var plen := _path_len(rs)
	if plen < MIN_LEN:
		return "none"
	if rs[0].distance_to(rs[rs.size() - 1]) / plen < CLOSED_RATIO:
		return "O"
	# Bekleme kalktı: iki-stroke X yok. Tek stroke kendini keserse X.
	if _self_crosses(rs):
		return "X"
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

# Tek stroke kendini kesiyor mu? Komşu segmentleri (paylaşılan uç) atla.
func _self_crosses(pts: PackedVector2Array) -> bool:
	for i in range(pts.size() - 1):
		for j in range(i + 2, pts.size() - 1):
			if Geometry2D.segment_intersects_segment(pts[i], pts[i + 1], pts[j], pts[j + 1]) != null:
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
			i += 2
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
