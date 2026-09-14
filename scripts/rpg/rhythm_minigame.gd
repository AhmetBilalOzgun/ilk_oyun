extends Node2D
class_name RhythmMinigame

# Büyü KOMBO ritim minigame'i (Piano Tiles / Retro Gesture Tiles).
# Beceri seçilince açılır: RASTGELE bir jest dizisi (5 yön: DOKUN ● / KAYDIR ◀ ▶ ▲ ▼)
# sağdan sola kayar. Tile hedef çizgiye gelince oyuncu DOĞRU jesti yapar:
#   yön yanlış / ıska -> KOMBO KIRILIR (kalan tile'lar düşer, sıra rakibe geçer).
#   doğru yön + ±0.11s -> MÜKEMMEL (haptik titreşim), ±0.26s -> HARİKA.
# Her tutturulan tile bir "vuruş"tur: host (battle.gd) o an bir büyü + hasar sayısı
# gösterir. SON tile FINISHER'dır — en ağır (en büyük hasar) vuruş.
#
# Dizi HER CAST'te rastgele üretilir (sabit değil); uzunluk (combo_len) host'tan gelir
# (run ilerledikçe uzar). Motor ritmi/jesti GÖRMEZ — kombo başarısı tek bir combo_score'a
# (0..1) indirgenir; host bunu float çarpana çevirip TurnManager.submit_input_multiplier'a
# verir (fail-soft: floor taban hasarı garanti). Görsel-motor sözleşmesi için bkz battle.gd.

# Her tile çözülünce (index, toplam, InputEvaluator.Result, finisher mi, hasar payı 0..1).
signal tile_resolved(index, total, result, is_finisher, fraction)
# Kombo bitince toplu sonuç: {combo_score: float 0..1, broke: bool, tiles: int}.
signal finished(payload)

const BEAT := 0.64            # notalar arası süre (sn) ~ 94 BPM (yavaşlatıldı)
const SPEED := 480.0          # nota kayma hızı (px/sn) — daha okunur/yavaş
const PERFECT_WINDOW := 0.13  # ±sn: bu kadar yakınsa PERFECT
const GOOD_WINDOW := 0.30     # ±sn: bu kadar yakınsa GOOD
const TAIL := 0.22            # son nota geçtikten sonra bekleme
const SWIPE_MIN_DIST := 35.0  # jest kaydırma eşiği (px)
const FINISHER_WEIGHT := 2.0  # son tile'ın hasar ağırlığı (normal tile = 1.0)
const Q_PERFECT := 1.0        # kalite katsayıları (fraction hesabı)
const Q_GOOD := 0.6
const PIXEL_FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")

# 5 yön havuzu — dizi buradan rastgele üretilir.
const STEP_POOL := [
	InputSequence.Step.TAP,
	InputSequence.Step.SWIPE_LEFT,
	InputSequence.Step.SWIPE_RIGHT,
	InputSequence.Step.SWIPE_UP,
	InputSequence.Step.SWIPE_DOWN,
]

var _rect: Rect2
var _hit_x: float
var _track_y: float
var _spawn_x: float
var _lead: float              # ilk notanın hedefe varış süresi
var _steps: Array = []
var _notes: Array = []        # {node, t, hit, result, step, is_finisher, weight}
var _clock := 0.0
var _finished := false
var _broke := false
var _sum_w := 1.0             # toplam ağırlık (fraction normalizasyonu)
var _hint: Label
var _ring: Node2D

var _touch_start_pos := Vector2.ZERO
var _touch_active := false
var _swiped_in_gesture := false

# combo_len: kaç tile (>=1). Son tile FINISHER. Dizi rastgele üretilir.
func setup(combo_len: int, rect: Rect2) -> void:
	_rect = rect
	var n: int = maxi(1, combo_len)
	_steps = []
	for i in range(n):
		_steps.append(STEP_POOL[randi() % STEP_POOL.size()])
	# Ağırlık toplamı: (n-1) normal + finisher.
	_sum_w = float(maxi(0, n - 1)) * 1.0 + FINISHER_WEIGHT
	_hit_x = rect.position.x + 160.0
	_track_y = rect.position.y + rect.size.y * 0.5
	_lead = 0.72
	_spawn_x = _hit_x + _lead * SPEED
	_build_frame()
	_build_notes()

# --- Kurulum ---

func _build_frame() -> void:
	# Ana panel (Pixel fantezi koyu arka plan)
	var panel := ColorRect.new()
	panel.color = Color(0.06, 0.05, 0.13, 0.94)
	panel.position = _rect.position
	panel.size = _rect.size
	panel.z_index = 0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	# Panel dış altın çerçevesi (3px)
	var border := ReferenceRect.new()
	border.position = _rect.position
	border.size = _rect.size
	border.border_color = Color(0.8, 0.65, 0.25, 0.85)
	border.border_width = 3.0
	border.editor_only = false
	border.z_index = 1
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	# Kayma şeridi (lane) - Pixel retro mavi/mor şerit
	var lane := ColorRect.new()
	lane.color = Color(0.1, 0.1, 0.2, 0.92)
	lane.size = Vector2(_rect.size.x - 40.0, 140.0)
	lane.position = Vector2(_rect.position.x + 20.0, _track_y - 70.0)
	lane.z_index = 1
	lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lane)

	# Şerit üst ve alt parlak çizgi
	var top_line := ColorRect.new()
	top_line.color = Color(0.35, 0.75, 1.0, 0.4)
	top_line.size = Vector2(_rect.size.x - 40.0, 2.0)
	top_line.position = Vector2(_rect.position.x + 20.0, _track_y - 70.0)
	top_line.z_index = 2
	add_child(top_line)

	var bot_line := ColorRect.new()
	bot_line.color = Color(0.35, 0.75, 1.0, 0.4)
	bot_line.size = Vector2(_rect.size.x - 40.0, 2.0)
	bot_line.position = Vector2(_rect.position.x + 20.0, _track_y + 68.0)
	bot_line.z_index = 2
	add_child(bot_line)

	# Hedef çizgi (dikey parlak altın bar) + hedef karesi
	var bar := ColorRect.new()
	bar.color = Color(1.0, 0.9, 0.35, 0.95)
	bar.size = Vector2(8.0, 160.0)
	bar.position = Vector2(_hit_x - 4.0, _track_y - 80.0)
	bar.z_index = 3
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	_ring = Node2D.new()
	_ring.position = Vector2(_hit_x, _track_y)
	_ring.z_index = 3

	# Hedef retro halka/kutu
	var target_box := ReferenceRect.new()
	target_box.position = Vector2(-46.0, -46.0)
	target_box.size = Vector2(92.0, 92.0)
	target_box.border_color = Color(1.0, 0.88, 0.3, 0.95)
	target_box.border_width = 4.0
	target_box.editor_only = false
	_ring.add_child(target_box)
	add_child(_ring)

	# Ritim nabzı
	var pulse := create_tween().set_loops()
	pulse.tween_property(_ring, "scale", Vector2(1.15, 1.15), BEAT * 0.5).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_ring, "scale", Vector2(1.0, 1.0), BEAT * 0.5).set_trans(Tween.TRANS_SINE)

	# İpucu etiketi (Pixel Font)
	_hint = Label.new()
	_hint.position = Vector2(_rect.position.x + 24.0, _rect.position.y + 12.0)
	_hint.add_theme_font_override("font", PIXEL_FONT)
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1.0))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_update_hint()

func _build_notes() -> void:
	for i in range(_steps.size()):
		var step_val: int = int(_steps[i])
		var is_fin: bool = i == _steps.size() - 1
		var t: float = _lead + float(i) * BEAT
		var node := Node2D.new()
		node.position = Vector2(_spawn_x, _track_y)
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

	var accent := Color(1.0, 0.78, 0.25)
	var symbol := "●"
	match step_val:
		InputSequence.Step.TAP:
			accent = Color(1.0, 0.78, 0.25)   # Amber Gold Dot
			symbol = "●"
		InputSequence.Step.SWIPE_LEFT:
			accent = Color(0.3, 0.85, 1.0)    # Cyan Left Arrow
			symbol = "◀"
		InputSequence.Step.SWIPE_RIGHT:
			accent = Color(0.85, 0.45, 1.0)   # Arcane Right Arrow
			symbol = "▶"
		InputSequence.Step.SWIPE_UP:
			accent = Color(0.35, 0.9, 0.5)    # Emerald Up Arrow
			symbol = "▲"
		InputSequence.Step.SWIPE_DOWN:
			accent = Color(1.0, 0.45, 0.35)   # Flame Down Arrow
			symbol = "▼"

	# Finisher: daha büyük kutu + kızıl-altın çerçeve (okunur "SON VURUŞ").
	var box: float = 100.0 if is_finisher else 84.0
	var half: float = box * 0.5
	var frame_col := Color(1.0, 0.5, 0.15) if is_finisher else accent

	# Pixel kutu arka planı
	var bg := ColorRect.new()
	bg.size = Vector2(box, box)
	bg.position = Vector2(-half, -half)
	bg.color = Color(0.12, 0.06, 0.06, 0.96) if is_finisher else Color(0.08, 0.08, 0.16, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# Çerçeve
	var frame := ReferenceRect.new()
	frame.size = Vector2(box, box)
	frame.position = Vector2(-half, -half)
	frame.border_color = frame_col
	frame.border_width = 5.0 if is_finisher else 3.5
	frame.editor_only = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)

	# Köşe vurguları (İç parıltı)
	var inner_bg := ColorRect.new()
	inner_bg.size = Vector2(box - 10.0, box - 10.0)
	inner_bg.position = Vector2(-half + 5.0, -half + 5.0)
	inner_bg.color = Color(frame_col.r, frame_col.g, frame_col.b, 0.15)
	inner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(inner_bg)

	# Ok / Nokta Sembolü (PixelFont)
	var lbl := Label.new()
	lbl.text = symbol
	lbl.add_theme_font_override("font", PIXEL_FONT)
	lbl.add_theme_font_size_override("font_size", 44 if is_finisher else 36)
	lbl.add_theme_color_override("font_color", accent.lightened(0.3))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(box, box)
	lbl.position = Vector2(-half, -half)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lbl)

	return root

func _update_hint() -> void:
	var done := 0
	for n in _notes:
		if n.get("hit", false):
			done += 1
	# Son vurma yaklaşınca oyuncuyu uyar.
	var tail := ""
	if _notes.size() >= 2 and done == _notes.size() - 1 and not _broke:
		tail = "  🔥 SON VURUŞ!"
	_hint.text = "⚡ KOMBO — DOĞRU JESTİ YAP (%d/%d)%s" % [done, _notes.size(), tail]

# --- Döngü ---

func _process(delta: float) -> void:
	if _finished or not is_inside_tree():
		return
	_clock += delta
	for n in _notes:
		if n.get("hit", false):
			continue
		var raw_node = n.get("node", null)
		if not is_instance_valid(raw_node):
			continue
		var node: Node2D = raw_node
		var x: float = _hit_x + (float(n["t"]) - _clock) * SPEED
		node.position.x = x
		if _clock > float(n["t"]) + GOOD_WINDOW:
			# Iskalandı -> KOMBO KIRILIR (kalan tile'lar düşer, sıra rakibe geçer).
			n["hit"] = true
			n["result"] = InputEvaluator.Result.MISS
			_pop("ISKA!", Color(0.95, 0.4, 0.35))
			tile_resolved.emit(_index_of(n), _notes.size(), InputEvaluator.Result.MISS, n["is_finisher"], 0.0)
			_break_combo()
			return
	# Bitiş: son nota + kuyruk geçti (kırılmadan tümü çözüldüyse).
	var last_t: float = _lead + float(maxi(0, _steps.size() - 1)) * BEAT
	if _clock > last_t + GOOD_WINDOW + TAIL:
		_finish()

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

# Jest sonucunu çizgiye en yakın VURULMAMIŞ notaya eşle (yön + zamanlama).
func _register_gesture(detected_step: int) -> void:
	var best: Dictionary = {}
	var best_err := GOOD_WINDOW + 0.001
	for n in _notes:
		if n.get("hit", false):
			continue
		var err: float = abs(float(n["t"]) - _clock)
		if err < best_err:
			best_err = err
			best = n
	if best.is_empty():
		return   # pencere dışı basış/jest -> yok say (fail-soft)

	best["hit"] = true
	var req_step: int = int(best.get("step", InputSequence.Step.TAP))
	var raw_node = best.get("node", null)
	var idx := _index_of(best)
	var is_fin: bool = best["is_finisher"]

	if detected_step != req_step:
		# Jest yönü yanlış! -> KOMBO KIRILIR.
		best["result"] = InputEvaluator.Result.MISS
		_pop("YANLIŞ YÖN!", Color(1.0, 0.35, 0.35))
		if is_instance_valid(raw_node):
			_fade_note(raw_node as Node2D)
		tile_resolved.emit(idx, _notes.size(), InputEvaluator.Result.MISS, is_fin, 0.0)
		_break_combo()
		return
	elif best_err <= PERFECT_WINDOW:
		best["result"] = InputEvaluator.Result.PERFECT
		_pop("MÜKEMMEL!", Color(0.35, 1.0, 0.5))
		Input.vibrate_handheld(40)   # haptik: yalnız MÜKEMMEL isabette
	else:
		best["result"] = InputEvaluator.Result.GOOD
		_pop("HARİKA!", Color(1.0, 0.85, 0.25))

	_flash_ring()
	if is_instance_valid(raw_node):
		_fade_note(raw_node as Node2D)
	# Hasar payı: ağırlık × kalite / toplam ağırlık.
	var q: float = Q_PERFECT if best["result"] == InputEvaluator.Result.PERFECT else Q_GOOD
	var fraction: float = float(best["weight"]) * q / _sum_w
	tile_resolved.emit(idx, _notes.size(), best["result"], is_fin, fraction)
	_update_hint()

func _index_of(note: Dictionary) -> int:
	for i in range(_notes.size()):
		if _notes[i] == note:
			return i
	return 0

# Kombo kırıldı: kalan tile'ları söndür, kısa bekleyip bitir (finisher düşer).
func _break_combo() -> void:
	if _broke or _finished:
		return
	_broke = true
	for n in _notes:
		if not n.get("hit", false):
			n["hit"] = true
			n["result"] = InputEvaluator.Result.MISS
			var rn = n.get("node", null)
			if is_instance_valid(rn):
				_fade_note(rn as Node2D)
	_update_hint()
	_finish()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit(_result_payload())

# Toplam kombo skoru (0..1): tutturulan tile paylarının toplamı.
func _result_payload() -> Dictionary:
	var score := 0.0
	for n in _notes:
		var r: int = int(n.get("result", -1))
		if r == InputEvaluator.Result.PERFECT:
			score += float(n["weight"]) * Q_PERFECT / _sum_w
		elif r == InputEvaluator.Result.GOOD:
			score += float(n["weight"]) * Q_GOOD / _sum_w
	return {"combo_score": clampf(score, 0.0, 1.0), "broke": _broke, "tiles": _notes.size()}

# --- Görsel yardımcı ---

func _pop(txt: String, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_override("font", PIXEL_FONT)
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1.0))
	lbl.position = Vector2(_hit_x - 60.0, _track_y - 120.0)
	lbl.z_index = 5
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -50.0), 0.5).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)

func _flash_ring() -> void:
	if _ring == null:
		return
	var tw := create_tween()
	tw.tween_property(_ring, "scale", Vector2(1.25, 1.25), 0.08)
	tw.tween_property(_ring, "scale", Vector2(1.0, 1.0), 0.12)

func _fade_note(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 0.0, 0.18)
	tw.tween_callback(node.queue_free)
