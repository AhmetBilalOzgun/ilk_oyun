extends RefCounted
class_name BattleDamage

# Turn-based hasar kuralı. Saf/statik. Sadece skill + hedef + config alır. Projenin
# iki ilkesini zorlar:
#   fail-soft: aktif girdi ıskası saldırıyı İPTAL ETMEZ, sadece çarpanı taban yapar.
#   hasar asla sıfırlanmaz: direnç düşürür ama min 1 (zaaf bonustur, kapı değil).
#
# Adımlar: base -> (*girdi çarpanı) -> (*zaaf VEYA *direnç) -> max(1, ...).

# cast_bonus: aktif girdi çarpanı (düşman/taban = 1.0, oyuncu = BattleConfig.input_multiplier;
# relic amp'leri TurnManager çarpıp buraya verir). relics: aktif relic kuralları
# (opsiyonel) — frozen_amp gibi hasar hook'ları burada uygulanır.
static func compute(skill: Skill, cast_bonus: float, target: Combatant, config: BattleConfig, relics: RelicSet = null) -> DamageBreakdown:
	var b := DamageBreakdown.new()
	b.base = skill.base_damage
	b.bonus_multiplier = cast_bonus
	b.input_success = cast_bonus > 1.0
	b.after_bonus = int(round(float(b.base) * b.bonus_multiplier))

	var eff := skill.effect
	b.weakness_multiplier = 1.0
	b.resist_multiplier = 1.0
	if eff != "":
		if target.weakness().has(eff):
			b.weakness_multiplier = config.weakness_multiplier
		elif target.resist().has(eff):
			# Relic: Delici — Shatter direnci deler (direnç uygulanmaz).
			var pierced := relics != null and eff == "Shatter" and relics.has("shatter_pierce")
			if not pierced:
				b.resist_multiplier = config.resist_multiplier

	# --- Relic hasar hook'ları ---
	var relic_mult := 1.0
	if relics != null:
		# Permafrost: sersem/donmuş hedefe hasar artışı.
		if target.stunned and relics.has("frozen_amp"):
			relic_mult *= relics.amount("frozen_amp", 1.0)
		# İnfaz: canı düşük hedefe (<%30) hasar artışı.
		if relics.has("execute"):
			var maxhp: int = target.source.max_hp
			if maxhp > 0 and float(target.hp) / float(maxhp) < 0.30:
				relic_mult *= relics.amount("execute", 1.0)
		# Ekipman: element hasar artışları (skill.effect'e göre). Düşman saldırıları
		# effect="" taşıdığından yalnız oyuncu becerilerinde tetiklenir.
		if eff == "Burn" and relics.has("burn_dmg_amp"):
			relic_mult *= relics.amount("burn_dmg_amp", 1.0)
		if eff == "Shatter" and relics.has("shatter_dmg_amp"):
			relic_mult *= relics.amount("shatter_dmg_amp", 1.0)

	var dmg := float(b.after_bonus) * b.weakness_multiplier * b.resist_multiplier * relic_mult
	b.final_damage = max(1, int(round(dmg)))   # asla sıfır
	return b
