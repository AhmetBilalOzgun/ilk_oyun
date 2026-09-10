extends Node2D

# Turn-based savaş sahnesi — QTE akışının motora BAĞLANMASI.
# Yandan bakış düzeni: KARAKTERLER SOLDA, DÜŞMANLAR SAĞDA, orta boş. Oyuncu sırası
# gelince ORTADA bir QTE minigame açılır (QteMinigame): hedef rünün soluk şablonu
# gösterilir, oyuncu parmakla takip eder, çizdikçe eleman renginde iz belirir
# (girdi görünür). Parmak kalkınca RecognizerAdapter tanır -> tm.submit_drawing.
# Fail-soft: tanınmazsa/süre dolarsa taban hasar.
#
# Not: hedef MVP'de otomatik (en düşük HP düşman). Hedef seçim UI'si sonraki iş.

var db: RuneDB
var recognizer: RecognizerAdapter
var tm: TurnManager
var overlay: TurnDebugOverlay
var mini: QteMinigame

# Çizim durumu (sadece QTE sırasında aktif).
var drawing := false
var current: PackedVector2Array = []
var strokes: Array = []

var skill_menu: VBoxContainer
var status_label: Label
var _bodies := {}   # Combatant -> {box, lbl, base_col}

var _last_usec := 0
var _next_turn_delay := 0.0   # NEXT_TURN'de pacing için bekleme

const NEXT_TURN_PAUSE := 0.8
const MINI_RECT := Rect2(260, 680, 560, 560)   # ekran ortası çizim alanı

# Eleman -> iz rengi (girdi görünür olsun). Strike/etkisiz -> beyaz.
const EFFECT_COLOR := {
	"Burn": Color(0.95, 0.45, 0.2, 1),
	"Freeze": Color(0.4, 0.75, 0.98, 1),
	"Push": Color(0.4, 0.85, 0.5, 1),
	"Shatter": Color(0.97, 0.87, 0.25, 1),
	"Steam": Color(0.88, 0.88, 0.92, 1),
}
const C_NEUTRAL := Color(0.85, 0.85, 0.9, 1)

func _ready() -> void:
	db = RuneDB.load_from_file()
	recognizer = RecognizerAdapter.new(db)
	tm = TurnManager.new(BattleConfig.new(), recognizer)

	tm.turn_started.connect(_on_turn_started)
	tm.qte_started.connect(_on_qte_started)
	tm.damage_resolved.connect(_on_damage_resolved)
	tm.dot_applied.connect(_on_dot_applied)
	tm.stun_skipped.connect(_on_stun_skipped)
	tm.battle_ended.connect(_on_battle_ended)

	# Beceri menüsü — alt orta.
	skill_menu = VBoxContainer.new()
	skill_menu.position = Vector2(300, 1320)
	add_child(skill_menu)

	# Durum yazısı — çizim alanının üstü.
	status_label = Label.new()
	status_label.position = Vector2(280, 600)
	status_label.add_theme_font_size_override("font_size", 32)
	add_child(status_label)

	overlay = TurnDebugOverlay.new()
	add_child(overlay)

	# QTE minigame — EN SON child (savaşçı kutularının üstüne çizsin). Başta gizli.
	mini = QteMinigame.new()
	mini.hide_game()
	add_child(mini)

	_last_usec = Time.get_ticks_usec()
	tm.start_battle(TestBattleData.party(), TestBattleData.enemies())
	_build_bodies()

# Her savaşçı için görünür kutu + isim/HP. Parti SOL sütun, düşman SAĞ sütun —
# ortadaki QTE alanını (MINI_RECT) boş bırakacak şekilde kenara yayılır.
func _build_bodies() -> void:
	var party_i := 0
	var enemy_i := 0
	for c in tm.combatants:
		var is_party: bool = c.side == Combatant.Side.PARTY
		var col: Color = Color(0.35, 0.55, 0.85, 1) if is_party else Color(0.80, 0.40, 0.35, 1)
		var box := ColorRect.new()
		box.size = Vector2(230, 150)
		box.color = col
		var x: float = 20.0 if is_party else 830.0
		var idx: int = party_i if is_party else enemy_i
		box.position = Vector2(x, 700.0 + idx * 180.0)
		add_child(box)
		var lbl := Label.new()
		lbl.position = box.position + Vector2(12, 12)
		lbl.add_theme_font_size_override("font_size", 26)
		add_child(lbl)
		_bodies[c] = {"box": box, "lbl": lbl, "base_col": col}
		if is_party:
			party_i += 1
		else:
			enemy_i += 1

# HP metni, ölü solması, aktif sıra vurgusu (parlak).
func _update_bodies() -> void:
	for c in _bodies.keys():
		var b: Dictionary = _bodies[c]
		var box: ColorRect = b["box"]
		var lbl: Label = b["lbl"]
		lbl.text = "%s\nHP %d" % [c.display_name(), c.hp]
		if c.side == Combatant.Side.PARTY:
			lbl.text += "\n⚡ %d/%d%s" % [c.charge, c.charge_max, "  DOLU" if c.is_charged() else ""]
		if c.stunned:
			lbl.text += "\n(stun)"
		if c.pending_dot > 0:
			lbl.text += "\n(yanıyor %d)" % c.pending_dot
		if not c.is_alive():
			box.color = Color(0.2, 0.2, 0.2, 1)
			lbl.text += "  (öldü)"
		elif c == tm.active:
			box.color = (b["base_col"] as Color).lightened(0.35)
		else:
			box.color = b["base_col"]

func _on_turn_started(actor: Combatant) -> void:
	_clear_menu()
	mini.hide_game()
	if actor.side == Combatant.Side.PARTY:
		status_label.text = "%s sırası — beceri seç" % actor.display_name()
		_build_skill_menu(actor)
	else:
		status_label.text = "%s sırası (düşman)" % actor.display_name()

func _build_skill_menu(actor: Combatant) -> void:
	for s in actor.skills():
		var btn := Button.new()
		if s.requires_charge:
			# Birleşim: kaynak rünleri peş peşe göster, şarj dolu değilse kilitle.
			var seq := " -> ".join(s.rune_sequence)
			btn.text = "%s  (birleşim: %s, %d hasar)" % [s.display_name, seq, s.base_damage]
			btn.disabled = not actor.is_charged()
			if btn.disabled:
				btn.text += "  [KİLİTLİ — şarj %d/%d]" % [actor.charge, actor.charge_max]
		else:
			btn.text = "%s  (rün: %s, %d hasar)" % [s.display_name, s.rune_id, s.base_damage]
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_skill_chosen.bind(s))
		skill_menu.add_child(btn)

func _on_skill_chosen(skill: Skill) -> void:
	var target := _lowest_hp_enemy()
	if target == null:
		return
	_clear_menu()
	tm.select_action(skill, target)

func _on_qte_started(skill: Skill, _target: Combatant, _limit: float, rune_id: String) -> void:
	# Ortada minigame'i aç: SIRADAKİ rünün şablonu + eleman renginde iz. Birleşimde
	# bu her adımda yeniden tetiklenir (ember -> storm), strokes sıfırlanır.
	strokes = []
	current = PackedVector2Array()
	drawing = false
	var col: Color = EFFECT_COLOR.get(skill.effect, C_NEUTRAL)
	mini.setup(rune_id, col, MINI_RECT)
	if skill.requires_charge:
		status_label.text = "BİRLEŞİM — ÇİZ: %s" % rune_id
	else:
		status_label.text = "ÇİZ: %s" % rune_id

func _on_damage_resolved(b: DamageBreakdown, attacker: Combatant, target: Combatant) -> void:
	mini.hide_game()
	strokes = []
	current = PackedVector2Array()
	status_label.text = "%s -> %s : %d hasar" % [
		attacker.display_name(), target.display_name(), b.final_damage]
	_next_turn_delay = NEXT_TURN_PAUSE

func _on_dot_applied(c: Combatant, amount: int) -> void:
	status_label.text = "%s yandı: %d hasar" % [c.display_name(), amount]

func _on_stun_skipped(c: Combatant) -> void:
	status_label.text = "%s sersemledi — sıra atlandı" % c.display_name()

func _on_battle_ended(winner_side: int) -> void:
	mini.hide_game()
	_clear_menu()
	status_label.text = "PARTİ KAZANDI" if winner_side == Combatant.Side.PARTY else "PARTİ YENİLDİ"

func _clear_menu() -> void:
	for c in skill_menu.get_children():
		c.queue_free()

func _lowest_hp_enemy() -> Combatant:
	var best: Combatant = null
	for c in tm._alive_on(Combatant.Side.ENEMY):
		if best == null or c.hp < best.hp:
			best = c
	return best

func _unhandled_input(event: InputEvent) -> void:
	if tm.state != TurnManager.State.QTE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and MINI_RECT.has_point(event.position):
			drawing = true
			current = PackedVector2Array([event.position])
		elif not event.pressed and drawing:
			drawing = false
			if current.size() >= 2:
				strokes.append(current)
			# Parmak kalktı -> tanıma + QTE çöz. Tanınmazsa null -> fail-soft taban.
			tm.submit_drawing(strokes)
	elif event is InputEventMouseMotion and drawing:
		current.append(event.position)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var unscaled_dt := float(now - _last_usec) / 1_000_000.0
	_last_usec = now

	tm.tick(unscaled_dt)

	# NEXT_TURN pacing: kısa nefes sonra sıradaki aktör.
	if tm.state == TurnManager.State.NEXT_TURN:
		_next_turn_delay -= unscaled_dt
		if _next_turn_delay <= 0.0:
			tm.advance_turn()

	if tm.state == TurnManager.State.QTE:
		mini.set_live(strokes, current, drawing)

	_update_bodies()
	overlay.update_view(tm)
