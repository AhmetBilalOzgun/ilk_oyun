extends RefCounted
class_name SkillCatalog

# Run-draft için beceri kataloğu. Saf/headless.
#   - normal beceriler: rune_id -> Skill (tek rün QTE). Draft bunlardan seçtirir.
#   - birleşim (combo) becerileri: kaynak rün dizisi (rune_sequence) tamamlanınca
#     loadout'ta OTOMATİK açılır. Yeni şekil yok — mevcut rünler peş peşe.
#
# Birleşim açılma kuralı RunLoadout.available_skills()'te: bir büyücü combo'nun
# TÜM kaynak rünlerini tutuyorsa combo becerisi kitine eklenir (bkz [[Turn-Based
# Savaş ve QTE]] — ember+storm=Plazma, frost+gale=Fırtına).

var _normal: Dictionary = {}   # rune_id -> Skill
var combos: Array = []         # Array[Skill] — her biri requires_charge + rune_sequence

func add_normal(skill: Skill) -> void:
	_normal[skill.rune_id] = skill

func add_combo(skill: Skill) -> void:
	combos.append(skill)

func normal_for_rune(rune_id: String) -> Skill:
	return _normal.get(rune_id, null)

func has_rune(rune_id: String) -> bool:
	return _normal.has(rune_id)

# Draft'ta teklif edilebilecek tüm normal rünler.
func rune_pool() -> Array:
	return _normal.keys()
