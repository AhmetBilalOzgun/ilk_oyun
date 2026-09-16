extends RefCounted
class_name TurnManager

# Turn-based savaş durum makinesi. Saf/headless: motor zamanı/geometri BİLMEZ.
# Çizim KALDIRILDI; yerine hafif AKTİF GİRDİ (tap/swipe dizisi). Oyuncu bir beceri
# seçer -> AWAITING_INPUT: host jesti yakalar, InputEvaluator ile PERFECT/GOOD/MISS
# üretir ve submit_input(result) ile verir. Motor jesti GÖRMEZ, sadece sonucu tüketir
# (bkz spec Part 19). FAIL-SOFT: MISS bile taban hasar verir (büyü iptal olmaz).
#
# Durumlar: IDLE -> SELECTING_ACTION -> AWAITING_INPUT -> RESOLVING -> NEXT_TURN -> ...
#
# İki beceri türü:
#   TEMEL    : formun temel büyüsü. Her zaman seçilebilir (fail-soft taban).
#   ULTIMATE : requires_charge. Enerji (şarj) barı dolunca seçilebilir; kullanınca
#              sıfırlanır. Yüksek taban + durum etkisi (yakma/stun/AoE).
#
# Şarj barı: her hasar VER/AL olayında vurana+yiyene miktar kadar eklenir.
# Durum: pending_dot (yakma) ve stunned sıra BAŞINDA işlenir (_begin_turn).

enum State { IDLE, SELECTING_ACTION, AWAITING_INPUT, RESOLVING, NEXT_TURN, BATTLE_OVER }

signal turn_started(actor)                          # Combatant
signal action_selected(skill, target)               # Skill, Combatant
signal input_requested(sequence)                    # InputSequence — host jesti yakalasın
signal damage_resolved(breakdown, attacker, target) # DamageBreakdown, Combatant, Combatant
signal dot_applied(combatant, amount)               # sıra başı yakma hasarı
signal stun_skipped(combatant)                       # stun nedeniyle atlanan sıra
signal combatant_defeated(combatant)               # bir katılımcı öldü (orb/işaret için)
signal battle_ended(winner_side)                    # Combatant.Side

var config: BattleConfig
var relics: RelicSet             # aktif relic kuralları (opsiyonel; null -> etkisiz)

var state: int = State.IDLE
var combatants: Array = []
var order: Array = []
var turn_index: int = 0
var round_index: int = 0        # kaç tur (wave) geçti — ritim minigame hızını ölçekler
var active: Combatant = null

# AWAITING_INPUT sırasında bekleyen eylem (submit_input ile çözülür).
var pending_skill: Skill = null
var pending_target: Combatant = null

var combat_rng := RandomNumberGenerator.new()

var last_breakdown: DamageBreakdown = null

func _init(p_config: BattleConfig = null, p_relics: RelicSet = null) -> void:
	combat_rng.randomize()
	config = p_config if p_config != null else BattleConfig.new()
	relics = p_relics if p_relics != null else RelicSet.new()

# --- Kurulum ---

func start_battle(party: Array, enemies: Array) -> void:
	combatants = []
	for c in party:
		combatants.append(Combatant.new(Combatant.Side.PARTY, c, config.charge_max))
	for e in enemies:
		combatants.append(Combatant.new(Combatant.Side.ENEMY, e, config.charge_max))
	round_index = 0
	_start_round()

# --- Sıra hesaplama ---

func _start_round() -> void:
	round_index += 1
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
		if not active.is_alive():
			combatant_defeated.emit(active)
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

# Beceri + hedef seç -> AKTİF GİRDİ bekle. requires_charge becerisi şarj dolu değilse
# reddedilir (UI de sunmamalı). Çözüm submit_input(result) gelince olur (fail-soft).
func select_action(skill: Skill, target: Combatant) -> void:
	if state != State.SELECTING_ACTION:
		return
	if skill.requires_charge and not active.is_charged():
		return   # ultimate henüz açık değil
	pending_skill = skill
	pending_target = target
	state = State.AWAITING_INPUT
	action_selected.emit(skill, target)
	input_requested.emit(skill.input_sequence)

# Host, aktif girdiyi değerlendirip sonucu (InputEvaluator.Result) buraya verir.
# Çarpan BattleConfig'ten gelir; MISS bile taban hasar verir (fail-soft).
func submit_input(result: int) -> void:
	if state != State.AWAITING_INPUT:
		return
	var skill := pending_skill
	var target := pending_target
	pending_skill = null
	pending_target = null
	var mult := config.input_multiplier(result)
	_apply_action(skill, target, mult, float(result) / float(InputEvaluator.Result.PERFECT))

# Ritim KOMBO yolu: host per-tile kaliteyi tek bir float çarpana indirger (bkz
# RhythmMinigame.combo_score) ve doğrudan verir. submit_input(enum) ile aynı çözümleme
# (_apply_action) — fark yalnız çarpanın sürekli olması (finisher ağırlıklı + kombo
# kırılma yansır). quality: 0..1 (görsel/telemetri; DamageBreakdown.input_quality).
func submit_input_multiplier(mult: float, quality: float = 1.0) -> void:
	if state != State.AWAITING_INPUT:
		return
	var skill := pending_skill
	var target := pending_target
	pending_skill = null
	pending_target = null
	_apply_action(skill, target, mult, quality)

# --- Çözümleme ---

func _run_enemy_turn() -> void:
	var act := EnemyAI.choose_action(active, _alive_on(Combatant.Side.PARTY), config)
	if act.is_empty():
		state = State.NEXT_TURN
		return
	action_selected.emit(act["skill"], act["target"])
	_apply_action(act["skill"], act["target"], 1.0, 0.0)  # düşman cast çarpanı yok -> taban

func _apply_action(skill: Skill, target: Combatant, cast_bonus: float, quality: float) -> void:
	state = State.RESOLVING
	# One roll per enemy action, including AoE. A miss applies no damage, status,
	# charge, reflection or splash. Player rhythm MISS remains fail-soft.
	if active.side == Combatant.Side.ENEMY and target.side == Combatant.Side.PARTY:
		var chance := clampf(relics.amount("enemy_miss_chance", 0.0), 0.0, 1.0)
		if chance > 0.0 and combat_rng.randf() < chance:
			var miss := DamageBreakdown.new()
			miss.base = skill.base_damage
			miss.missed = true
			last_breakdown = miss
			if skill.requires_charge:
				active.consume_charge()
			state = State.NEXT_TURN
			damage_resolved.emit(miss, active, target)
			return
	# Relic: Storm sonrası güçlenme (post_storm_amp) — aktörde biriken buff'ı uygula.
	var extra := 1.0
	if active.pending_amp > 1.0:
		extra = active.pending_amp
		active.pending_amp = 1.0
	var b := BattleDamage.compute(skill, cast_bonus * extra, target, config, relics)
	b.input_quality = quality
	last_breakdown = b
	target.take_damage(b.final_damage)
	var by_party := active.side == Combatant.Side.PARTY
	if by_party:
		Input.vibrate_handheld(30)   # haptik: oyuncu hasar verince titret

	# Relic: Kan Bağı — oyuncu verdiği hasarın bir kısmını can olarak alır.
	if by_party and relics.has("lifesteal"):
		active.heal(int(round(float(b.final_damage) * relics.amount("lifesteal", 0.0))))

	# Ekipman: Diken Zırhı — düşman vurunca hasarın bir kısmı saldırgana döner.
	if not by_party and relics.has("reflect"):
		var refl := int(round(float(b.final_damage) * relics.amount("reflect", 0.0)))
		if refl > 0:
			active.take_damage(refl)
			if not active.is_alive():
				combatant_defeated.emit(active)

	# Şarj: verilen ve alınan hasar barı doldurur. Relic Kondansatör dolumu hızlandırır.
	var charge_mult := relics.amount("charge_gain_mult", 1.0) if by_party else 1.0
	active.gain_charge(int(round(float(b.final_damage) * charge_mult)))
	target.gain_charge(b.final_damage)

	# Durum etkileri (birleşim kimliği): yakma DoT + stun.
	if skill.dot_fraction > 0.0 and target.is_alive():
		# Relic: Köz — oyuncu DoT'u daha sert vurur.
		var dot_mult := relics.amount("dot_amp", 1.0) if by_party else 1.0
		var dot := int(round(float(b.final_damage) * skill.dot_fraction * dot_mult))
		target.pending_dot += dot
		# Relic: Wildfire — yakma komşu düşmanlara da yayılır.
		if relics.has("burn_spread"):
			for n in _neighbors_of(target):
				n.pending_dot += dot
	if skill.applies_stun and target.is_alive():
		target.stunned = true

	# ULTIMATE AoE (Inferno / Plasma Storm): hedefin komşularına da vurur. Her komşu
	# kendi zaaf/direncine göre hesaplanır; DoT/stun de yayılır. Şarj yalnız birincil
	# hedeften kazanılır (splash sade).
	if skill.aoe:
		for n in _neighbors_of(target):
			var sb := BattleDamage.compute(skill, cast_bonus * extra, n, config, relics)
			n.take_damage(sb.final_damage)
			if skill.dot_fraction > 0.0 and n.is_alive():
				n.pending_dot += int(round(float(sb.final_damage) * skill.dot_fraction))
			if skill.applies_stun and n.is_alive():
				n.stunned = true
			if not n.is_alive():
				combatant_defeated.emit(n)

	# Build: Patlama (basic_splash) — normal (AoE olmayan) party saldırısı da komşulara
	# yayılır. Playstyle: tek hedef yerine alan. Splash düz (birincil hasarın bir oranı).
	if by_party and not skill.aoe and relics.has("basic_splash"):
		var sp := int(round(float(b.final_damage) * relics.amount("basic_splash", 0.0)))
		if sp > 0:
			for n in _neighbors_of(target):
				n.take_damage(sp)
				if not n.is_alive():
					combatant_defeated.emit(n)

	# Relic: Overcharge — Storm cast'inden sonra AKTÖRÜN bir sonraki cast'i güçlenir.
	if active.side == Combatant.Side.PARTY and skill.effect == "Shatter":
		active.pending_amp = relics.amount("post_storm_amp", 1.0)

	# Birleşim becerisi şarjı tüketir (başarısız olsa bile — commit edildi).
	if skill.requires_charge:
		active.consume_charge()

	state = State.NEXT_TURN
	damage_resolved.emit(b, active, target)
	if not target.is_alive():
		combatant_defeated.emit(target)
		# Build: Zincir Patlama (on_kill_aoe) — party öldürünce komşulara patlama.
		if by_party and relics.has("on_kill_aoe"):
			var boom := int(round(float(b.final_damage) * relics.amount("on_kill_aoe", 0.0)))
			if boom > 0:
				for n in _neighbors_of(target):
					n.take_damage(boom)
					if not n.is_alive():
						combatant_defeated.emit(n)
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

# Hedefle AYNI tarafta, hedef HARİÇ canlı katılımcılar (Wildfire yayılımı için).
func _neighbors_of(target: Combatant) -> Array:
	var out: Array = []
	for c in combatants:
		if c != target and c.side == target.side and c.is_alive():
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
