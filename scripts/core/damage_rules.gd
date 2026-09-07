extends RefCounted
class_name DamageRules

# Zaaf kuralı — ComboResolver saf kalsın diye AYRI (resolver düşmanı bilmez).
# Düşman zaafı büyünün etkileriyle eşleşmezse hasar SIFIRLANMAZ, %40'a düşer.
# Doğru rün ödüllendirilir, yanlış rün cezalandırılmaz (bkz [[Zaaf Bonustur]]).

static func apply_weakness(damage: int, spell_effects: Array, enemy_weakness, db: RuneDB) -> int:
	if enemy_weakness == null or enemy_weakness == "":
		return damage
	if spell_effects.has(enemy_weakness):
		return damage
	return int(round(damage * db.weakness_wrong_effect_multiplier))
