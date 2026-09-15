extends RefCounted
class_name SkillCatalog

# Run-draft için form + relic kataloğu. Saf/headless.
#   - forms      : form_id -> MageForm (her form kendi temel büyü + ultimate'ini taşır).
#   - transforms : (from_form_id, rune_id) -> to_form_id. Rün alınca kimlik DÖNÜŞÜR
#                  (bkz spec Part 5). MVP: (ember, storm) -> plasma.
#   - relics     : kural-değiştiren kartlar (CHOICE havuzu).
#
# Combo/rün-dizisi modeli KALDIRILDI — dönüşüm artık formu KOMPLE değiştirir, üstüne
# beceri EKLEMEZ (bkz RunLoadout.available_skills).

var forms: Dictionary = {}       # form_id -> MageForm
var transforms: Dictionary = {}  # "from_id|rune_id" -> to_form_id
var relics: Array = []           # Array[Relic]
var archetypes: Array = []       # Array[Archetype] — form başına build katmanı havuzu

func add_form(p_form: MageForm) -> void:
	forms[p_form.id] = p_form

func form(form_id: String) -> MageForm:
	return forms.get(form_id, null)

func add_transform(from_id: String, rune_id: String, to_id: String) -> void:
	transforms["%s|%s" % [from_id, rune_id]] = to_id

# from_id formu rune_id alırsa hangi forma döner? Yoksa "" (dönüşüm yok).
func transform_for(from_id: String, rune_id: String) -> String:
	return transforms.get("%s|%s" % [from_id, rune_id], "")

# Herhangi bir dönüşümde geçen tüm rün id'leri (CHOICE'ta teklif için).
func acquirable_runes() -> Array:
	var out: Array = []
	for key in transforms.keys():
		var rune: String = String(key).split("|")[1]
		if rune not in out:
			out.append(rune)
	return out

func add_relic(relic: Relic) -> void:
	relics.append(relic)

func add_archetype(a: Archetype) -> void:
	archetypes.append(a)

# Verilen forma uygulanabilir build arketipleri (CHOICE'ta teklif için).
func archetypes_for(form_id: String) -> Array:
	var out: Array = []
	for a in archetypes:
		if a.form_id == form_id:
			out.append(a)
	return out
