extends RefCounted
class_name RunLoadout

# Bir büyücünün TEK RUN boyunca durumu. Saf/headless. Character (meta tanım) sabit —
# bu onu sarar, run içinde DÖNÜŞEN kimliği (current_form) + taşınan HP/şarjı tutar,
# run bitince atılır.
#
# KİMLİK DÖNÜŞÜMÜ (spec Part 5): büyücü bir başlangıç formuyla girer (Kor=Ember).
# CHOICE'ta rün alınca form KOMPLE değişir (Ember + Storm -> Plazma): temel büyü,
# aktif girdi, pasif, ultimate hepsi yeni. available_skills() sadece güncel formun
# becerilerini verir — eski beceriler kalmaz.

var character: Character
var current_form: MageForm
var current_hp: int          # savaşlar arası taşınan can
var bonus_max_hp: int = 0    # run-içi +max HP boost'ları
var charge: int = 0          # savaşlar (wave) arası taşınan şarj — geçişte %X düşer

func _init(p_character: Character, p_form: MageForm = null) -> void:
	character = p_character
	current_form = p_form
	current_hp = p_character.max_hp

func max_hp() -> int:
	return character.max_hp + bonus_max_hp

func heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp())

func heal_full() -> void:
	current_hp = max_hp()

func raise_max_hp(amount: int) -> void:
	bonus_max_hp += amount
	current_hp += amount   # boost anında efektif canı da yükseltir

# Savaş (wave) bitişinde şarjı taşı ama decay kadar düşür (bileşik, asla <0).
func store_charge(current: int, decay: float) -> void:
	charge = max(0, int(round(current * (1.0 - decay))))

# Güncel formun becerileri: temel büyü + (varsa) ultimate.
func available_skills() -> Array[Skill]:
	return current_form.skills() if current_form != null else []

# Rün al -> uygun bir dönüşüm varsa formu değiştir. Dönüşen yeni formu döndürür
# (yoksa null). ChoiceOption dönüşüm hedefini önceden hesaplayıp transform_to
# çağırabilir; bu, catalog erişimi olan yer için kolaylık.
func acquire_rune(rune_id: String, catalog: SkillCatalog) -> MageForm:
	if current_form == null:
		return null
	var to_id := catalog.transform_for(current_form.id, rune_id)
	if to_id == "":
		return null
	var f := catalog.form(to_id)
	if f != null:
		current_form = f
	return f

func transform_to(form: MageForm) -> void:
	if form != null:
		current_form = form
