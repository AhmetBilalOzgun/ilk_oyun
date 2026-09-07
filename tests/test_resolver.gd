extends RefCounted

# ComboResolver saf mantık testleri: öncelik (taşıyıcı), füzyon, hasar çarpanı.

static func run(t) -> void:
	var db: RuneDB = t.fixture()

	t.section("öncelik-taşıyıcı")
	var s1 := ComboResolver.resolve(["ember", "frost"], db)
	t.check(s1.carrier == "Projectile", "ilk rün (ember) taşıyıcılık kazanır")
	var s2 := ComboResolver.resolve(["frost", "ember"], db)
	t.check(s2.carrier == "Cone", "ilk rün (frost) taşıyıcılık kazanır")

	t.section("füzyon-eşleşme")
	# Burn + Freeze -> Steam (tek etki)
	t.check(s1.effects.size() == 1 and s1.effects[0] == "Steam",
		"Burn+Freeze -> Steam füzyonu (etkiler: %s)" % [s1.effects])
	t.check(s1.fusion_notes.size() == 1, "füzyon notu kaydedildi")

	t.section("füzyon-eşleşmeyen")
	# Burn + Push -> füzyon yok, yan yana
	var s3 := ComboResolver.resolve(["ember", "gale"], db)
	t.check(s3.effects.has("Burn") and s3.effects.has("Push") and s3.effects.size() == 2,
		"eşleşmeyen etkiler yan yana (etkiler: %s)" % [s3.effects])

	t.section("strike-etkisiz")
	var s4 := ComboResolver.resolve(["strike"], db)
	t.check(s4.carrier == "Projectile" and s4.effects.is_empty(),
		"strike: taşıyıcı Projectile, etki yok")
	# strike komboyu taşır ama füzyona etki katmaz
	var s5 := ComboResolver.resolve(["ember", "strike"], db)
	t.check(s5.effects.size() == 1 and s5.effects[0] == "Burn",
		"strike füzyona etki katmaz (etkiler: %s)" % [s5.effects])

	t.section("hasar-çarpanı")
	t.eqf(float(ComboResolver.resolve(["ember"], db).damage), 20.0, "tek rün taban hasar")
	t.eqf(float(ComboResolver.resolve(["ember", "ember"], db).damage), 32.0, "2 rün: 20*1.6")
	t.eqf(float(ComboResolver.resolve(["ember", "ember", "ember"], db).damage), 51.0,
		"3 rün: 20*1.6*1.6=51.2->51 (çarpımsal)")
	# taban HER ZAMAN ilk ründen
	t.eqf(float(ComboResolver.resolve(["frost", "ember"], db).damage), 29.0,
		"taban ilk rün (frost 18): 18*1.6=28.8->29")

	t.section("zaaf-kuralı")
	# yanlış etki -> %40, sıfır değil
	t.eqf(float(DamageRules.apply_weakness(100, ["Burn"], "Freeze", db)), 40.0,
		"yanlış rün: %40 hasar")
	t.eqf(float(DamageRules.apply_weakness(100, ["Freeze"], "Freeze", db)), 100.0,
		"doğru rün: tam hasar")
	t.eqf(float(DamageRules.apply_weakness(100, ["Burn"], null, db)), 100.0,
		"zaafsız düşman: tam hasar")
