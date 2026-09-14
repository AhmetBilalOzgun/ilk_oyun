extends RefCounted
class_name DamageBreakdown

# Hasar hesabının AYRIŞTIRILMIŞ çıktısı. Debug overlay taban + bonus + zaaf/direnç
# çarpanlarını ayrı ayrı gösterebilsin diye her adım saklanır. Saf veri.

var base: int = 0                   # skill.base_damage (garanti taban)
var input_success: bool = false     # bonus_multiplier > 1.0 (MISS üstü sonuç)
var input_quality: float = 0.0      # [0,1] aktif girdi kalitesi (UI/övgü için)
var bonus_multiplier: float = 1.0   # aktif girdi sonucu -> çarpan (MISS=1.0 .. PERFECT)
var after_bonus: int = 0            # base * bonus_multiplier
var weakness_multiplier: float = 1.0
var resist_multiplier: float = 1.0
var final_damage: int = 0           # uygulanan nihai hasar (asla 0)

func describe() -> String:
	return "taban %d | girdi %s x%.2f -> %d | zaaf x%.2f | direnç x%.2f | SON %d" % [
		base, ("BAŞARI" if input_success else "taban"), bonus_multiplier, after_bonus,
		weakness_multiplier, resist_multiplier, final_damage]
