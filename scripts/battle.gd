extends Node2D

# Run host sahnesi — RunManager omurgasını OYNANIR hale getirir.
# Akış: RunManager düğümleri gezer. BATTLE/BOSS'ta bu host bir TurnManager kurup
# savaşı sürer (QTE çizimi dahil); savaş bitince sonucu report_battle_result ile
# RunManager'a bildirir. CHOICE'ta seçim ekranı (rün draftı / boost) gösterir,
# tıklamada apply_choice çağırır. REWARD/bitiş -> run_ended ekranı.
#
# Yandan bakış düzeni: KARAKTERLER SOLDA, DÜŞMANLAR SAĞDA, orta QTE minigame.
# Rün-draft: büyücünün becerileri RunLoadout.available_skills(catalog)'ten gelir —
# kaynak çifti toplanınca birleşim (Plazma/Fırtına) menüde otomatik belirir.
# HP savaşlar arası taşınır (RunLoadout.current_hp); kazanınca düşenler %25 canla
# dirilir (MVP — run soft-lock olmasın). Tüm parti ölürse RUN_LOST.

var db: RuneDB
var recognizer: RecognizerAdapter

# Run omurgası.
var rm: RunManager
var catalog: SkillCatalog
var run_state: RunState

# Aktif savaş (CHOICE sırasında null).
var tm: TurnManager = null

var overlay: TurnDebugOverlay
var mini: QteMinigame

# Çizim durumu (sadece QTE sırasında aktif).
var drawing := false
var current: PackedVector2Array = []
var strokes: Array = []

var skill_menu: VBoxContainer    # savaşta beceri menüsü / seçimde draft seçenekleri
var status_label: Label
var _bodies := {}   # Combatant -> {box, lbl, base_col}

var _last_usec := 0
var _next_turn_delay := 0.0

const HOME := "res://scenes/home.tscn"
const NEXT_TURN_PAUSE := 0.8
const MINI_RECT := Rect2(260, 680, 560, 560)
const REVIVE_FRACTION := 0.25   # kazanınca düşen parti üyesi bu oranda dirilir

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

	# Run omurgasını kur. Meta CAN upgrade'i parti max HP'sine baklanır (run
	# current_hp de buradan dolar). HASAR upgrade'i savaş başında becerilere eklenir.
	catalog = RunContent.catalog()
	var party := RunContent.party()
	for c in party:
		c.max_hp += Meta.hp_bonus(c.id)
	run_state = RunState.new(party, RunContent.base_runes())
	rm = RunManager.new(catalog)
	rm.battle_requested.connect(_on_battle_requested)
	rm.choice_requested.connect(_on_choice_requested)
	rm.run_ended.connect(_on_run_ended)

	# Ortak UI.
	skill_menu = VBoxContainer.new()
	skill_menu.position = Vector2(300, 1320)
	add_child(skill_menu)

	status_label = Label.new()
	status_label.position = Vector2(280, 600)
	status_label.add_theme_font_size_override("font_size", 32)
	add_child(status_label)

	overlay = TurnDebugOverlay.new()
	add_child(overlay)

	mini = QteMinigame.new()
	mini.hide_game()
	add_child(mini)

	_last_usec = Time.get_ticks_usec()
	rm.start(RunContent.stage_nodes(Meta.selected_level), run_state)

# =========================================================================
#  RUN omurgası olayları
# =========================================================================

# BATTLE/BOSS düğümü: verilen düşman setiyle yeni bir savaş kur.
func _on_battle_requested(enemies: Array) -> void:
	_clear_menu()
	_clear_bodies()
	_start_battle(enemies)

func _on_choice_requested(options: Array) -> void:
	# Savaş bitti; seçim ekranı. Gövdeler/minigame temiz, menüye seçenekler.
	tm = null
	_clear_bodies()
	mini.hide_game()
	_clear_menu()
	status_label.text = "SEÇİM — bir ödül al (%s)" % _progress_text()
	for i in range(options.size()):
		var opt: ChoiceOption = options[i]
		var btn := Button.new()
		btn.text = _choice_label(opt)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_choice_chosen.bind(i))
		skill_menu.add_child(btn)

func _choice_label(opt: ChoiceOption) -> String:
	match opt.kind:
		ChoiceOption.Kind.DRAFT_RUNE:
			var cid: String = opt.params["char_id"]
			var rid: String = opt.params["rune_id"]
			var cname: String = run_state.loadout(cid).character.display_name
			var hint := _combo_hint(cid, rid)
			return "🔮 %s'e RÜN: %s%s" % [cname, rid, hint]
		ChoiceOption.Kind.HEAL:
			return "❤️ %s" % opt.label
		ChoiceOption.Kind.MAX_HP:
			return "➕ %s" % opt.label
	return opt.label

# Bu rünü eklersek bir birleşimin kaynak çifti tamamlanıyor mu? Kullanıcıya ipucu.
func _combo_hint(char_id: String, rune_id: String) -> String:
	var lo: RunLoadout = run_state.loadout(char_id)
	for combo in catalog.combos:
		var req: Array = combo.qte_runes()
		if rune_id in req and not lo.has_rune(rune_id):
			var complete := true
			for r in req:
				if r != rune_id and not lo.has_rune(r):
					complete = false
					break
			if complete:
				return "  ⚡(%s AÇILIR!)" % combo.display_name
	return ""

func _on_choice_chosen(index: int) -> void:
	_clear_menu()
	rm.apply_choice(index)   # -> sıradaki düğüm (battle_requested / run_ended)

func _on_run_ended(won: bool) -> void:
	tm = null
	_clear_menu()
	_clear_bodies()
	mini.hide_game()
	var lvl: int = Meta.selected_level
	if won:
		# Ödülü Meta'ya yaz + seviyeyi aç (sonraki kilidi açılır).
		var cry: int = RunContent.reward_crystal(lvl)
		Meta.add_gold(run_state.gold)
		Meta.add_crystal(cry)
		Meta.clear_level(lvl)
		status_label.text = "BÖLÜM TAMAMLANDI 🏆  +%d💰  +%d💎" % [run_state.gold, cry]
	else:
		status_label.text = "PARTİ YENİLDİ — run bitti (%s)" % _progress_text()
	# Ana ekrana dönüş.
	var home_btn := Button.new()
	home_btn.text = "ANA EKRAN"
	home_btn.add_theme_font_size_override("font_size", 40)
	home_btn.pressed.connect(func(): get_tree().change_scene_to_file(HOME))
	skill_menu.add_child(home_btn)

func _progress_text() -> String:
	return "düğüm %d/%d" % [run_state.node_index + 1, rm.nodes.size()]

# =========================================================================
#  SAVAŞ kurulumu (run-içi loadout -> geçici Character)
# =========================================================================

func _start_battle(enemies: Array) -> void:
	tm = TurnManager.new(BattleConfig.new(), recognizer)
	tm.turn_started.connect(_on_turn_started)
	tm.qte_started.connect(_on_qte_started)
	tm.damage_resolved.connect(_on_damage_resolved)
	tm.dot_applied.connect(_on_dot_applied)
	tm.stun_skipped.connect(_on_stun_skipped)
	tm.battle_ended.connect(_on_battle_ended)

	# Her loadout -> geçici Character (draft edilmiş beceriler + run max HP).
	var party_chars: Array = []
	for lo in run_state.ordered_loadouts():
		var c := Character.new()
		c.id = lo.character.id
		c.display_name = lo.character.display_name
		c.element_pair = lo.character.element_pair
		c.max_hp = lo.max_hp()
		c.speed = lo.character.speed
		# HASAR upgrade'i: becerileri kopyala, flat bonus ekle (katalog paylaşımlı —
		# orijinali mutasyona uğratma).
		var pb: int = Meta.power_bonus(lo.character.id)
		var sk: Array[Skill] = []
		for s in lo.available_skills(catalog):
			if pb > 0:
				var s2: Skill = s.duplicate()
				s2.base_damage += pb
				sk.append(s2)
			else:
				sk.append(s)
		c.skills = sk
		party_chars.append(c)

	tm.start_battle(party_chars, enemies)

	# Taşınan HP'yi Combatant'lara yaz (start_battle max_hp ile doldurur).
	for cmb in tm.combatants:
		if cmb.side == Combatant.Side.PARTY:
			var lo := run_state.loadout(cmb.source.id)
			if lo != null:
				cmb.hp = clampi(lo.current_hp, 1, lo.max_hp())

	_build_bodies()
	status_label.text = "SAVAŞ — %s" % _progress_text()

# =========================================================================
#  SAVAŞ olayları (TurnManager) — büyük ölçüde eski host mantığı
# =========================================================================

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

# Savaş bitti -> HP'yi loadout'lara geri yaz, RunManager'a sonucu bildir.
func _on_battle_ended(winner_side: int) -> void:
	mini.hide_game()
	_clear_menu()
	var won := winner_side == Combatant.Side.PARTY
	if won:
		_save_party_hp()
	# report_battle_result sıradaki düğümü tetikler (battle/choice/run_ended).
	rm.report_battle_result(won)

# Hayatta kalan parti HP'sini taşı; düşen üyeyi %25 ile dirilt (soft-lock önle).
func _save_party_hp() -> void:
	for cmb in tm.combatants:
		if cmb.side != Combatant.Side.PARTY:
			continue
		var lo := run_state.loadout(cmb.source.id)
		if lo == null:
			continue
		if cmb.hp > 0:
			lo.current_hp = cmb.hp
		else:
			lo.current_hp = max(1, int(round(lo.max_hp() * REVIVE_FRACTION)))

# =========================================================================
#  Görseller + girdi + döngü
# =========================================================================

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

func _clear_bodies() -> void:
	for c in _bodies.keys():
		var b: Dictionary = _bodies[c]
		(b["box"] as Node).queue_free()
		(b["lbl"] as Node).queue_free()
	_bodies.clear()

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
		elif tm != null and c == tm.active:
			box.color = (b["base_col"] as Color).lightened(0.35)
		else:
			box.color = b["base_col"]

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
	if tm == null or tm.state != TurnManager.State.QTE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and MINI_RECT.has_point(event.position):
			drawing = true
			current = PackedVector2Array([event.position])
		elif not event.pressed and drawing:
			drawing = false
			if current.size() >= 2:
				strokes.append(current)
			tm.submit_drawing(strokes)
	elif event is InputEventMouseMotion and drawing:
		current.append(event.position)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var unscaled_dt := float(now - _last_usec) / 1_000_000.0
	_last_usec = now

	if tm != null:
		tm.tick(unscaled_dt)
		if tm.state == TurnManager.State.NEXT_TURN:
			_next_turn_delay -= unscaled_dt
			if _next_turn_delay <= 0.0:
				tm.advance_turn()
		if tm.state == TurnManager.State.QTE:
			mini.set_live(strokes, current, drawing)
		_update_bodies()
		overlay.update_view(tm)
