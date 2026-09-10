extends RefCounted
class_name RunLoadout

# Bir büyücünün TEK RUN boyunca geçici rün kiti. Saf/headless. Character (meta
# tanım) değişmez — bu onu sarar, run içinde draft edilen rünleri tutar, run
# bitince atılır (kit sıfırlanır). HP de run boyunca taşınır (savaşlar arası).
#
# available_skills(): tutulan her rün için normal beceri + kaynak rünleri tam
# olan her birleşim (combo). Birleşim böyle EMERGENT açılır — çifti draft et,
# ultimate gelsin.

var character: Character
var runes: Array = []       # tutulan rune_id'ler (bu run)
var current_hp: int         # savaşlar arası taşınan can
var bonus_max_hp: int = 0   # run-içi +max HP boost'ları

func _init(p_character: Character, base_runes: Array = []) -> void:
	character = p_character
	runes = base_runes.duplicate()
	current_hp = p_character.max_hp

func max_hp() -> int:
	return character.max_hp + bonus_max_hp

func has_rune(rune_id: String) -> bool:
	return rune_id in runes

func add_rune(rune_id: String) -> void:
	if rune_id not in runes:
		runes.append(rune_id)

func heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp())

func heal_full() -> void:
	current_hp = max_hp()

func raise_max_hp(amount: int) -> void:
	bonus_max_hp += amount
	current_hp += amount   # boost anında efektif canı da yükseltir

# Bu kitle kullanılabilir tüm beceriler: tutulan rünlerin normalleri + kaynak
# rünleri tam olan birleşimler.
func available_skills(catalog: SkillCatalog) -> Array[Skill]:
	var out: Array[Skill] = []
	for r in runes:
		var s: Skill = catalog.normal_for_rune(r)
		if s != null:
			out.append(s)
	for combo in catalog.combos:
		if _has_all(combo.qte_runes()):
			out.append(combo)
	return out

func _has_all(required: Array) -> bool:
	for r in required:
		if r not in runes:
			return false
	return true
