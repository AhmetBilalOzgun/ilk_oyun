extends RefCounted

# MageForm + dönüşüm haritası testleri (saf). Kimlik-değiştirme modeli: her form
# kendi temel büyü + ultimate + aktif girdisini taşır; Ember + Storm -> Plazma.

static func run(t) -> void:
	t.section("mage_form")
	var cat := RunContent.catalog()

	var ember := cat.form("ember")
	t.check(ember != null and ember.id == "ember", "ember formu var")
	t.check(ember.basic_spell != null, "ember temel büyü var")
	t.check(ember.basic_spell.input_sequence != null and ember.basic_spell.input_sequence.size() == 3,
		"ember temel girdi 3 adım")
	t.check(ember.basic_spell.dot_fraction > 0.0, "ember pasifi: temel büyü yakar (dot_fraction>0)")
	t.check(ember.ultimate != null and ember.ultimate.requires_charge, "ember ultimate şarj ister")
	t.check(ember.skills().size() == 2, "ember 2 beceri (temel + ultimate)")

	var plasma := cat.form("plasma")
	t.check(plasma != null and plasma.id == "plasma", "plazma formu var")
	t.check(plasma.basic_spell.input_sequence.size() == 3, "plazma temel girdi 3 adım")
	t.check(plasma.ultimate.applies_stun, "plazma ultimate stun uygular")
	t.check(plasma.ultimate.aoe, "plazma ultimate AoE")

	# Kimlik değişince aktif girdi de değişir (spec Part 5).
	t.check(ember.basic_spell.input_sequence.steps != plasma.basic_spell.input_sequence.steps,
		"form değişince girdi dizisi değişir")

	t.section("transform_map")
	t.check(cat.transform_for("ember", "storm") == "plasma", "ember + storm -> plasma")
	t.check(cat.transform_for("plasma", "storm") == "", "plazma'nın dönüşümü yok (MVP)")
	t.check(cat.transform_for("ember", "frost") == "", "tanımsız rün -> dönüşüm yok")
	t.check("storm" in cat.acquirable_runes(), "storm alınabilir rün listesinde")
