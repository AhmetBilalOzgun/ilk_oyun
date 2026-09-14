extends RefCounted
class_name OrbBoardResult

# Cup Heroes tarzı fizik board'unun SAF skorlama yardımcısı. Fizik sahnesi
# (orb_board.gd) sadece hangi orb'un hangi slot çarpanına düştüğünü bildirir;
# çarpan -> DRAFT PUANI dönüşümü burada yapılır (headless -> test edilebilir).
#
# Puan = Σ(orb_value × slot_multiplier). orb_value orb başına taban değer.

const ORB_VALUE := 10

static func score(slot_multipliers: Array, orb_value: int = ORB_VALUE) -> int:
	var total := 0.0
	for m in slot_multipliers:
		total += float(orb_value) * float(m)
	return int(round(total))
