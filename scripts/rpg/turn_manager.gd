extends RefCounted
class_name TurnManager

# Turn-based savaş durum makinesi. Saf/headless: motor zamanı OKUMAZ — tick()
# dışarıdan ÖLÇEKLENMEMİŞ dt alır. Geometri/çizim bilmez; QTE sonucu rune_id
# olarak dışarıdan verilir (submit_qte).
#
# Durumlar: IDLE -> SELECTING_ACTION -> QTE -> RESOLVING -> NEXT_TURN -> ...
#
# İki beceri türü:
#   NORMAL   : tek rün QTE.
#   BİRLEŞİM : requires_charge + rune_sequence. Şarj barı dolunca seçilebilir,
#              QTE'de kaynak rünler PEŞ PEŞE çizilir (her adım doğru -> ilerle),
#              tamamı doğru -> büyük buff. Kullanınca şarj sıfırlanır.
#
# Şarj barı: her hasar VER/AL olayında vurana+yiyene miktar kadar eklenir.
# Durum: pending_dot (yakma) ve stunned sıra BAŞINDA işlenir (_begin_turn).

enum State { IDLE, SELECTING_ACTION, QTE, RESOLVING, NEXT_TURN, BATTLE_OVER }

signal turn_started(actor)                          # Combatant
signal action_selected(skill, target)               # Skill, Combatant
signal qte_started(skill, target, time_limit, rune_id)  # sıradaki çizilecek rün
signal damage_resolved(breakdown, attacker, target) # DamageBreakdown, Combatant, Combatant
signal dot_applied(combatant, amount)               # sıra başı yakma hasarı
signal stun_skipped(combatant)                       # stun nedeniyle atlanan sıra
signal battle_ended(winner_side)                    # Combatant.Side

var config: BattleConfig
var recognizer: IRuneRecognizer  # QTE tanıma; opsiyonel

var state: int = State.IDLE
var combatants: Array = []
var order: Array = []
var turn_index: int = 0
var active: Combatant = null

# QTE durumu
var pending_skill: Skill = null
var pending_target: Combatant = null
var qte_remaining: float = 0.0
var qte_sequence: Array = []   # bu QTE'de çizilecek rün dizisi
var qte_progress: int = 0      # kaç rün doğru çizildi
var last_breakdown: DamageBreakdown = null

func _init(p_config: BattleConfig = null, p_recognizer: IRuneRecognizer = null) -> void:
	config = p_config if p_config != null else BattleConfig.new()
	recognizer = p_recognizer

# --- Kurulum ---

func start_battle(party: Array, enemies: Array) -> void:
	combatants = []
	for c in party:
		combatants.append(Combatant.new(Combatant.Side.PARTY, c, config.charge_max))
	for e in enemies:
		combatants.append(Combatant.new(Combatant.Side.ENEMY, e, config.charge_max))
	_start_round()

# --- Sıra hesaplama ---

func _start_round() -> void:
	order = []
	for c in combatants:
		if c.is_alive():
			order.append(c)
	# Stabil azalan sıralama (speed yüksek önce).
	for i in range(order.size()):
		var best := i
		for j in range(i + 1, order.size()):
			if order[j].speed() > order[best].speed():
				best = j
		if best != i:
			var tmp = order[i]
			order[i] = order[best]
			order[best] = tmp
	turn_index = 0
	if _check_battle_end() != -1:
		return
	_begin_turn()

func _begin_turn() -> void:
	# Ölü aktörleri atla.
	while turn_index < order.size() and not order[turn_index].is_alive():
		turn_index += 1
	if turn_index >= order.size():
		_start_round()
		return
	active = order[turn_index]
	turn_started.emit(active)

	# Sıra başı durumları: önce yakma (pending_dot), sonra stun.
	if active.pending_dot > 0:
		var d: int = active.pending_dot
		active.pending_dot = 0
		active.take_damage(d)
		active.gain_charge(d)   # alınan hasar barı doldurur
		dot_applied.emit(active, d)
		var w := _check_battle_end()
		if w != -1:
			state = State.BATTLE_OVER
			battle_ended.emit(w)
			return
		if not active.is_alive():
			state = State.NEXT_TURN   # yakma öldürdü -> sıra atlanır
			return

	if active.stunned:
		active.stunned = false
		stun_skipped.emit(active)
		state = State.NEXT_TURN
		return

	if active.side == Combatant.Side.ENEMY:
		_run_enemy_turn()
	else:
		state = State.SELECTING_ACTION

# --- Oyuncu sırası ---

# Beceri + hedef seç -> QTE aç. requires_charge becerisi şarj dolu değilse reddedilir.
func select_action(skill: Skill, target: Combatant) -> void:
	if state != State.SELECTING_ACTION:
		return
	if skill.requires_charge and not active.is_charged():
		return   # birleşim henüz açık değil (UI de sunmamalı)
	pending_skill = skill
	pending_target = target
	qte_sequence = skill.qte_runes()
	qte_progress = 0
	state = State.QTE
	qte_remaining = skill.qte_time_limit
	action_selected.emit(skill, target)
	qte_started.emit(skill, target, qte_remaining, qte_sequence[0])

# Motor çizimi bitirince çağırır: recognizer ile rune_id bul, adımı çöz.
func submit_drawing(strokes) -> void:
	var rid = recognizer.recognize(strokes) if recognizer != null else null
	submit_qte(rid)

# Tanınan rune_id (veya null) ile QTE adımını çöz. Dizide sıradaki rünü bekler.
# Doğru -> ilerle (dizi bitince başarı). Yanlış/null -> dizi başarısız (fail-soft).
func submit_qte(recognized_rune_id) -> void:
	if state != State.QTE:
		return
	var expected = qte_sequence[qte_progress]
	if recognized_rune_id != null and recognized_rune_id == expected:
		qte_progress += 1
		if qte_progress >= qte_sequence.size():
			_resolve(true)
		else:
			# Sıradaki rün: pencereyi yenile, UI'a bildir.
			qte_remaining = pending_skill.qte_time_limit
			qte_started.emit(pending_skill, pending_target, qte_remaining, qte_sequence[qte_progress])
	else:
		_resolve(false)

# --- Zaman ilerletme (ÖLÇEKLENMEMİŞ dt) ---

func tick(unscaled_dt: float) -> void:
	if state != State.QTE:
		return
	qte_remaining -= unscaled_dt
	if qte_remaining <= 0.0:
		qte_remaining = 0.0
		_resolve(false)

# --- Çözümleme ---

func _resolve(qte_success: bool) -> void:
	state = State.RESOLVING
	_apply_action(pending_skill, pending_target, qte_success)
	pending_skill = null
	pending_target = null
	qte_sequence = []
	qte_progress = 0

func _run_enemy_turn() -> void:
	var act := EnemyAI.choose_action(active, _alive_on(Combatant.Side.PARTY), config)
	if act.is_empty():
		state = State.NEXT_TURN
		return
	action_selected.emit(act["skill"], act["target"])
	_apply_action(act["skill"], act["target"], false)  # düşman QTE yapmaz -> taban

func _apply_action(skill: Skill, target: Combatant, qte_success: bool) -> void:
	var b := BattleDamage.compute(skill, qte_success, target, config)
	target.take_damage(b.final_damage)
	last_breakdown = b

	# Şarj: verilen ve alınan hasar barı doldurur.
	active.gain_charge(b.final_damage)
	target.gain_charge(b.final_damage)

	# Durum etkileri (birleşim kimliği): yakma DoT + stun.
	if skill.dot_fraction > 0.0 and target.is_alive():
		target.pending_dot += int(round(float(b.final_damage) * skill.dot_fraction))
	if skill.applies_stun and target.is_alive():
		target.stunned = true

	# Birleşim becerisi şarjı tüketir (başarısız olsa bile — commit edildi).
	if skill.requires_charge:
		active.consume_charge()

	state = State.NEXT_TURN
	damage_resolved.emit(b, active, target)
	var winner := _check_battle_end()
	if winner != -1:
		state = State.BATTLE_OVER
		battle_ended.emit(winner)

func advance_turn() -> void:
	if state == State.BATTLE_OVER:
		return
	if state != State.NEXT_TURN:
		return
	turn_index += 1
	if turn_index >= order.size():
		_start_round()
	else:
		_begin_turn()

# --- Yardımcılar ---

func _alive_on(side: int) -> Array:
	var out: Array = []
	for c in combatants:
		if c.side == side and c.is_alive():
			out.append(c)
	return out

func _check_battle_end() -> int:
	var party_alive := _alive_on(Combatant.Side.PARTY).size()
	var enemy_alive := _alive_on(Combatant.Side.ENEMY).size()
	if enemy_alive == 0:
		return Combatant.Side.PARTY
	if party_alive == 0:
		return Combatant.Side.ENEMY
	return -1
