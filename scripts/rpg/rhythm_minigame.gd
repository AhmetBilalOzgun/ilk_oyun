extends Node2D
class_name RhythmMinigame

# Sektör standardı ritim şeridi (Guitar Hero / Beatstar okunurluğu):
# Notalar sağdan sola akar, SABİT İSABET ÇİZGİSİNE varınca jesti yap.
# Tek referans = çizgi. Notalar aynı anda görünür, oyuncu "ne zaman"ı çizgiden okur.
# FAIL-SOFT per-nota: yanlış yön ya da kaçan pencere yalnız O notayı düşürür —
# komboyu ÖLDÜRMEZ, kalan notalar akmaya devam eder (oyunun sessiz-başarısızlık-yok ilkesi).
# Motor sözleşmesi aynı: tile_resolved + finished, fail-soft kombo skoru.

# Her tile çözülünce (index, toplam, InputEvaluator.Result, finisher mi, hasar payı 0..1).
signal tile_resolved(index, total, result, is_finisher, fraction)
# Kombo bitince toplu sonuç: {combo_score: float 0..1, broke: bool, tiles: int}.
signal finished(payload)

const BEAT_BASE := 0.64       # notalar arası temel süre (sn) ~ 94 BPM
const SPEED_BASE := 480.0     # nota kayma temel hızı (px/sn)
const SPEED_MIN_SCALE := 0.6  # hız çarpanı tabanı (<1.0: adaptive kolaylaştırma — yeni/60 yaş)
const SPEED_MAX_SCALE := 2.2  # hız çarpanı tavanı (waveler geçtikçe artan)
const PERFECT_WINDOW := 0.16  # ±sn: bu kadar yakınsa PERFECT (geniş — okunurluk)
const GOOD_WINDOW := 0.36     # ±sn: bu kadar yakınsa GOOD
const TAIL := 0.28            # son nota geçtikten sonra bekleme
const SWIPE_MIN_DIST := 35.0  # jest kaydırma eşiği (px)
const FINISHER_WEIGHT := 2.0  # son tile'ın hasar ağırlığı (normal tile = 1.0)
const Q_PERFECT := 1.0        # kalite katsayıları (fraction hesabı)
const Q_GOOD := 0.6
const HIT_HALF := 92.0        # isabet çizgisi görsel yarı-yükseklik (px)
const PIXEL_FONT = preload("res://assets/fonts/PixelifySans-Bold.ttf")

# 5 yön havuzu — dizi buradan rastgele üretilir.
const STEP_POOL := [
	InputSequence.Step.TAP,
	InputSequence.Step.SWIPE_LEFT,
	InputSequence.Step.SWIPE_RIGHT,
	InputSequence.Step.SWIPE_UP,
	InputSequence.Step.SWIPE_DOWN,
]

var _rect: Rect2
var _hit_x: float             # SABİT isabet çizgisi x'i
var _track_y: float
var _lane_right: float        # notaların doğduğu sağ kenar
var _lead: float              # ilk notanın çizgiye varış süresi (spawn->hit)
var _beat: float = BEAT_BASE  # bu cast'in nota aralığı (hız ölçeğine göre kısalır)
var _speed: float = SPEED_BASE # bu cast'in kayma hızı (hız ölçeğine göre artar)
var _steps: Array = []
var _notes: Array = []        # {node, t, hit, result, step, is_finisher, weight}
var _clock := 0.0
var _finished := false
var _missed := 0              # kaç nota ıskalandı (broke hesabı)
var _sum_w := 1.0             # toplam ağırlık (fraction normalizasyonu)
var _hint: Label
var _line: Node2D             # sabit isabet çizgisi + bant
var _timing_label: Label
var _line_glow := 0.0         # çizgi vurgusu (yakın nota olunca yükselir)

var _touch_start_pos := Vector2.ZERO
var _touch_active := false
var _swiped_in_gesture := false

# combo_len: kaç tile (>=1). Son tile FINISHER. Dizi rastgele üretilir.
# speed_scale: host'tan gelen hız çarpanı = wave ölçeği × adaptive skill (Meta).
#   >1.0 => daha hızlı, <1.0 => daha yavaş. [SPEED_MIN_SCALE, SPEED_MAX_SCALE] kırpılır.
func setup(combo_len: int, rect: Rect2, speed_scale: float = 1.0) -> void:
	_rect = rect
	var k: float = clampf(speed_scale, SPEED_MIN_SCALE, SPEED_MAX_SCALE)
	_speed = SPEED_BASE * k
	# Uzaysal aralık sabit kalsın diye BEAT ters ölçekle kısalır (SPEED*BEAT sabit).
	_beat = BEAT_BASE / k
	var n: int = maxi(1, combo_len)
	_steps = []
	for i in range(n):
		_steps.append(STEP_POOL[randi() % STEP_POOL.size()])
	# Ağırlık toplamı: (n-1) normal + finisher.
	_sum_w = float(maxi(0, n - 1)) * 1.0 + FINISHER_WEIGHT
	# İsabet çizgisi solda-ortada; notalar sağ kenardan doğup çizgiye akar.
	_hit_x = _rect.position.x + _rect.size.x * 0.30
	_track_y = _rect.position.y + _rect.size.y * 0.46
	_lane_right = _rect.end.x - 60.0
	_lead = maxf(0.35, (_lane_right - _hit_x) / _speed)
	_build_frame()
	_build_notes()
	_update_hint()
	_process(0.0)

# --- Kurulum ---

func _build_frame() -> void:
	GameLook.card(self, _rect)
	_line = Node2D.new()
	_line.z_index = 1
	_line.draw.connect(_draw_line)
	add_child(_line)
	_hint = GameLook.label("NOTA ÇİZGİYE GELİNCE JESTİ YAP", 28)
	_hint.position = _rect.position + Vector2(20, 16)
	_hint.size.x = _rect.size.x - 40
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)
	_timing_label = GameLook.label("HAZIRLAN", 34)
	_timing_label.position = Vector2(_rect.position.x, _track_y + HIT_HALF + 26)
	_timing_label.size.x = _rect.size.x
	_timing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_timing_label)

# Sabit isabet çizgisi: GOOD penceresi genişliğinde soluk bant + PERFECT çekirdeği + dikey çizgi.
func _draw_line() -> void:
	if _finished:
		return
	var top := Vector2(_hit_x, _track_y - HIT_HALF)
	var bot := Vector2(_hit_x, _track_y + HIT_HALF)
	# GOOD bandı (geniş, soluk) — "buraya kadar iyi" hissi.
	var good_w: float = GOOD_WINDOW * _speed
	_line.draw_rect(Rect2(_hit_x - good_w, _track_y - HIT_HALF, good_w * 2.0, HIT_HALF * 2.0),
		Color(GameLook.TEAL.r, GameLook.TEAL.g, GameLook.TEAL.b, 0.10))
	# PERFECT çekirdeği (dar, parlak).
	var perf_w: float = PERFECT_WINDOW * _speed
	_line.draw_rect(Rect2(_hit_x - perf_w, _track_y - HIT_HALF, perf_w * 2.0, HIT_HALF * 2.0),
		Color(GameLook.TEAL.r, GameLook.TEAL.g, GameLook.TEAL.b, 0.18 + 0.35 * _line_glow))
	# Dikey isabet çizgisi (parlar).
	var lc: Color = GameLook.TEAL.darkened(0.15).lerp(GameLook.CREAM, _line_glow)
	_line.draw_line(top, bot, lc, 7.0)
	# Küçük üçgen işaretçiler (üstte/altta çizgiyi vurgular).
	_line.draw_colored_polygon(PackedVector2Array([
		top + Vector2(-14, -18), top + Vector2(14, -18), top]), lc)
	_line.draw_colored_polygon(PackedVector2Array([
		bot + Vector2(-14, 18), bot + Vector2(14, 18), bot]), lc)

func _build_notes() -> void:
	for i in range(_steps.size()):
		var step_val: int = int(_steps[i])
		var is_fin: bool = i == _steps.size() - 1
		var t: float = _lead + float(i) * _beat
		var node := Node2D.new()
		node.position = Vector2(_lane_right, _track_y)
		node.z_index = 2
		var tile := _create_pixel_tile(step_val, is_fin)
		node.add_child(tile)
		add_child(node)
		_notes.append({
			"node": node, "t": t, "hit": false, "result": -1,
			"step": step_val, "is_finisher": is_fin,
			"weight": FINISHER_WEIGHT if is_fin else 1.0,
		})

# Retro Pixel Tile Oluşturucu (Oklar & Nokta). Finisher tile daha büyük + kızıl vurgu.
func _create_pixel_tile(step_val: int, is_finisher: bool) -> Node2D:
	var root := Node2D.new()
	var accent := GameLook.CORAL if is_finisher else GameLook.TEAL
	var plate := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(32):
		points.append(Vector2.from_angle(TAU * i / 32.0) * 46)
	plate.polygon = points
	plate.color = accent.lightened(0.65)
	root.add_child(plate)
	var ring := Line2D.new()
	ring.points = points
	ring.closed = true
	ring.width = 3
	ring.default_color = accent.darkened(0.25)
	root.add_child(ring)
	if step_val == InputSequence.Step.TAP:
		var l := GameLook.label("TAP", 26)
		l.position = Vector2(-44, -44)
		l.size = Vector2(88, 88)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		root.add_child(l)
	else:
		# Native pixel arrow: no font-dependent missing glyphs.
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(-27,-8), Vector2(5,-8), Vector2(5,-24), Vector2(29,0), Vector2(5,24), Vector2(5,8), Vector2(-27,8)])
		arrow.color = GameLook.INK
		match step_val:
			InputSequence.Step.SWIPE_LEFT: arrow.rotation = PI
			InputSequence.Step.SWIPE_UP: arrow.rotation = -PI / 2
			InputSequence.Step.SWIPE_DOWN: arrow.rotation = PI / 2
		root.add_child(arrow)
	return root

func _update_hint() -> void:
	var done := 0
	for n in _notes:
		if n.get("hit", false):
			done += 1
	_hint.text = "NOTA ÇİZGİYE GELİNCE JESTİ YAP   %d / %d" % [mini(done + 1, _notes.size()), _notes.size()]

# Çizgiye zaman olarak EN YAKIN vurulmamış nota (lane'de birden fazla görünürken doğru hedef).
func _nearest_pending() -> int:
	var best := -1
	var best_err := 1e9
	for i in range(_notes.size()):
		if _notes[i]["hit"]:
			continue
		var err: float = absf(float(_notes[i]["t"]) - _clock)
		if err < best_err:
			best_err = err
			best = i
	return best

func _process(delta: float) -> void:
	if _finished or not is_inside_tree():
		return
	_clock += delta
	# Notaları çizgiye göre konumla (x = çizgi + kalan_süre × hız). Kaçan pencere -> MISS (devam).
	for i in range(_notes.size()):
		var note: Dictionary = _notes[i]
		if note["hit"]:
			continue
		var node: Node2D = note["node"]
		if is_instance_valid(node):
			var x: float = _hit_x + (float(note["t"]) - _clock) * _speed
			node.position = Vector2(x, _track_y)
			node.scale = Vector2.ONE * (1.25 if note["is_finisher"] else 1.0)
			# Çizgiye yakınken hafif büyü + tam opak; uzakken biraz soluk.
			var near: float = clampf(1.0 - absf(x - _hit_x) / (GOOD_WINDOW * _speed + 1.0), 0.0, 1.0)
			node.scale *= 1.0 + 0.22 * near
			node.modulate.a = lerpf(0.55, 1.0, near)
		# Pencere tamamen geçti -> ıska (fail-soft, komboyu bitirmez).
		if _clock > float(note["t"]) + GOOD_WINDOW:
			_miss_note(i, "ISKA!")
	# Çizgi vurgusu: en yakın notanın yakınlığına göre.
	var nearest := _nearest_pending()
	if nearest < 0:
		# Tüm notalar çözüldü -> kısa kuyruk sonra bitir.
		if _clock > _last_time() + TAIL:
			_finish()
		_line_glow = 0.0
		_line.queue_redraw()
		return
	var cur: Dictionary = _notes[nearest]
	var err: float = absf(float(cur["t"]) - _clock)
	_line_glow = clampf(1.0 - err / GOOD_WINDOW, 0.0, 1.0)
	var now := err <= PERFECT_WINDOW
	var action: String = ["DOKUN", "SOLA KAYDIR", "SAĞA KAYDIR", "YUKARI KAYDIR", "AŞAĞI KAYDIR"][int(cur["step"])]
	_timing_label.text = ("ŞİMDİ!  " if now else "HAZIRLAN  ") + action
	if cur["is_finisher"]:
		_timing_label.text += " · SON VURUŞ"
	_timing_label.add_theme_color_override("font_color", GameLook.TEAL.darkened(0.3) if now else GameLook.INK)
	_line.queue_redraw()

func _last_time() -> float:
	var t := 0.0
	for n in _notes:
		t = maxf(t, float(n["t"]))
	return t

# --- Girdi (Jest Algılama: TAP & SWIPE) ---

func _input(event: InputEvent) -> void:
	if _finished:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_start_pos = event.position
			_touch_active = true
			_swiped_in_gesture = false
		else:
			if _touch_active and not _swiped_in_gesture:
				_touch_active = false
				_register_gesture(InputSequence.Step.TAP)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _touch_active and not _swiped_in_gesture:
		var diff: Vector2 = event.position - _touch_start_pos
		if diff.length() >= SWIPE_MIN_DIST:
			_swiped_in_gesture = true
			_touch_active = false
			_register_gesture(_vector_to_step(diff))
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_pos = event.position
			_touch_active = true
			_swiped_in_gesture = false
		else:
			if _touch_active and not _swiped_in_gesture:
				_touch_active = false
				_register_gesture(InputSequence.Step.TAP)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _touch_active and not _swiped_in_gesture:
		var diff: Vector2 = event.position - _touch_start_pos
		if diff.length() >= SWIPE_MIN_DIST:
			_swiped_in_gesture = true
			_touch_active = false
			_register_gesture(_vector_to_step(diff))
			get_viewport().set_input_as_handled()

func _vector_to_step(diff: Vector2) -> int:
	if abs(diff.x) >= abs(diff.y):
		return InputSequence.Step.SWIPE_RIGHT if diff.x > 0 else InputSequence.Step.SWIPE_LEFT
	else:
		return InputSequence.Step.SWIPE_DOWN if diff.y > 0 else InputSequence.Step.SWIPE_UP

# Jesti çizgiye zaman olarak EN YAKIN vurulmamış notaya eşle. FAIL-SOFT: yanlış yön/kaçış
# yalnız o notayı düşürür; kombo devam eder.
func _register_gesture(detected_step: int) -> void:
	var idx := _nearest_pending()
	if idx < 0:
		return
	var best: Dictionary = _notes[idx]
	var best_err := absf(float(best["t"]) - _clock)
	if best_err > GOOD_WINDOW:
		# Henüz erken -> notayı harcama, çizgiyi izlemesini söyle.
		_timing_label.text = "BİRAZ BEKLE · ÇİZGİYİ İZLE"
		return

	best["hit"] = true
	var req_step: int = int(best.get("step", InputSequence.Step.TAP))
	var raw_node = best.get("node", null)
	var is_fin: bool = best["is_finisher"]

	if detected_step != req_step:
		# Yanlış yön -> bu nota ıskalandı ama kombo YAŞAR (fail-soft).
		best["result"] = InputEvaluator.Result.MISS
		_missed += 1
		_pop("YANLIŞ YÖN!", Color(1.0, 0.55, 0.4))
		if is_instance_valid(raw_node):
			_fade_note(raw_node as Node2D)
		tile_resolved.emit(idx, _notes.size(), InputEvaluator.Result.MISS, is_fin, 0.0)
		_update_hint()
		return

	if best_err <= PERFECT_WINDOW:
		best["result"] = InputEvaluator.Result.PERFECT
		_pop("MÜKEMMEL!", Color(0.35, 1.0, 0.5))
		Input.vibrate_handheld(40)   # haptik: yalnız MÜKEMMEL isabette
	else:
		best["result"] = InputEvaluator.Result.GOOD
		_pop("HARİKA!", Color(1.0, 0.85, 0.25))

	_flash_line()
	if is_instance_valid(raw_node):
		_fade_note(raw_node as Node2D)
	# Hasar payı: ağırlık × kalite / toplam ağırlık.
	var q: float = Q_PERFECT if best["result"] == InputEvaluator.Result.PERFECT else Q_GOOD
	var fraction: float = float(best["weight"]) * q / _sum_w
	tile_resolved.emit(idx, _notes.size(), best["result"], is_fin, fraction)
	_update_hint()

# Kaçan pencere -> nota ıskalandı (fail-soft). Komboyu bitirmez.
func _miss_note(idx: int, txt: String) -> void:
	var note: Dictionary = _notes[idx]
	if note["hit"]:
		return
	note["hit"] = true
	note["result"] = InputEvaluator.Result.MISS
	_missed += 1
	var rn = note.get("node", null)
	if is_instance_valid(rn):
		_fade_note(rn as Node2D)
	_pop(txt, Color(0.85, 0.6, 0.5))
	tile_resolved.emit(idx, _notes.size(), InputEvaluator.Result.MISS, note["is_finisher"], 0.0)
	_update_hint()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit(_result_payload())

# Toplam kombo skoru (0..1): tutturulan tile paylarının toplamı.
# broke: hard-break yok; notaların yarısından çoğu ıskalandıysa "zorlandı" say (adaptive için).
func _result_payload() -> Dictionary:
	var score := 0.0
	for n in _notes:
		var r: int = int(n.get("result", -1))
		if r == InputEvaluator.Result.PERFECT:
			score += float(n["weight"]) * Q_PERFECT / _sum_w
		elif r == InputEvaluator.Result.GOOD:
			score += float(n["weight"]) * Q_GOOD / _sum_w
	var broke: bool = _missed * 2 > _notes.size()
	return {"combo_score": clampf(score, 0.0, 1.0), "broke": broke, "tiles": _notes.size()}

# --- Görsel yardımcı ---

func _pop(txt: String, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_override("font", PIXEL_FONT)
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1.0))
	lbl.position = Vector2(_hit_x - 90.0, _track_y - HIT_HALF - 44.0)
	lbl.z_index = 5
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -50.0), 0.5).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)

func _flash_line() -> void:
	if _line == null:
		return
	var tw := create_tween()
	tw.tween_property(_line, "modulate", Color(1.3, 1.3, 1.0), 0.06)
	tw.tween_property(_line, "modulate", Color.WHITE, 0.12)

func _fade_note(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 0.0, 0.18)
	tw.tween_callback(node.queue_free)
