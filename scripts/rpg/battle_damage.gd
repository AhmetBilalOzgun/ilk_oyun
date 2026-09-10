extends RefCounted
class_name BattleDamage

# Turn-based hasar kuralı. Saf/statik. ComboResolver düşmanı bilmediği gibi, bu da
# sadece skill + hedef + config alır. Projenin iki ilkesini zorlar:
#   fail-soft: QTE başarısızlığı saldırıyı İPTAL ETMEZ, sadece bonusu kaybettirir.
#   hasar asla sıfırlanmaz: direnç düşürür ama min 1 (zaaf bonustur, kapı değil).
#
# Adımlar: base -> (QTE başarılıysa *bonus) -> (*zaaf VEYA *direnç) -> max(1, ...).

static func compute(skill: Skill, qte_success: bool, target: Combatant, config: BattleConfig) -> DamageBreakdown:
	var b := DamageBreakdown.new()
	b.base = skill.base_damage
	b.qte_success = qte_success
	b.bonus_multiplier = skill.qte_bonus_multiplier if qte_success else 1.0
	b.after_bonus = int(round(float(b.base) * b.bonus_multiplier))

	var eff := skill.effect
	b.weakness_multiplier = 1.0
	b.resist_multiplier = 1.0
	if eff != "":
		if target.weakness().has(eff):
			b.weakness_multiplier = config.weakness_multiplier
		elif target.resist().has(eff):
			b.resist_multiplier = config.resist_multiplier

	var dmg := float(b.after_bonus) * b.weakness_multiplier * b.resist_multiplier
	b.final_damage = max(1, int(round(dmg)))   # asla sıfır
	return b
