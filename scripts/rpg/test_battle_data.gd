extends RefCounted
class_name TestBattleData

# Basit test verisi: 2 parti üyesi + 2 düşman. Kodla kurulur (.tres değil) ki
# headless testlerden sahne/editör olmadan çağrılabilsin. rune_id'ler RuneDB
# (combo_config.json) şekil->rün eşlemesiyle uyumlu: ember/frost/gale/storm.
#
# Her karakter 3 büyü: 2 rün-özel NORMAL + 1 BİRLEŞİM (şarj barı dolunca).
# Birleşim QTE'de kaynak rünleri PEŞ PEŞE çizer, büyük buff alır.
#   Kayra: Plazma = ember->storm, başarıda yakma (sonraki tur %40 tekrar hasar).
#   Derin: Fırtına = frost->gale, başarıda stun (hedef bir tur atlar).

static func _skill(id: String, name: String, rune: String, base: int,
		limit: float, bonus: float, carrier: String, effect: String) -> Skill:
	return Skill.new(id, name, rune, base, limit, bonus, carrier, effect)

static func party() -> Array:
	var kayra := Character.new()
	kayra.id = "kayra"
	kayra.display_name = "Kayra"
	kayra.element_pair = ["Ateş", "Yıldırım"]
	kayra.max_hp = 90
	kayra.speed = 14
	var plazma := _skill("plasma", "Plazma", "", 44, 2.0, 2.5, "Beam", "Burn")
	plazma.requires_charge = true
	plazma.rune_sequence = ["ember", "storm"]
	plazma.dot_fraction = 0.40   # sonraki tur: son hasarın %40'ı yakma
	kayra.skills = [
		_skill("fireball", "Alev Topu", "ember", 20, 2.0, 1.5, "Projectile", "Burn"),
		_skill("shatterwave", "Kırılma Dalgası", "storm", 24, 1.6, 1.4, "Area", "Shatter"),
		plazma,
	]

	var derin := Character.new()
	derin.id = "derin"
	derin.display_name = "Derin"
	derin.element_pair = ["Su", "Rüzgar"]
	derin.max_hp = 70
	derin.speed = 18
	var firtina := _skill("tempest", "Fırtına", "", 33, 1.8, 2.5, "Storm", "Freeze")
	firtina.requires_charge = true
	firtina.rune_sequence = ["frost", "gale"]
	firtina.applies_stun = true   # hedef bir sonraki turunu atlar
	derin.skills = [
		_skill("frostbite", "Buz Isırığı", "frost", 18, 1.8, 1.6, "Cone", "Freeze"),
		_skill("gust", "Rüzgar", "gale", 15, 2.2, 1.5, "Wave", "Push"),
		firtina,
	]

	return [kayra, derin]

static func enemies() -> Array:
	var golem := Enemy.new()
	golem.id = "golem"
	golem.display_name = "Taş Golem"
	golem.max_hp = 120
	golem.speed = 8
	golem.weakness_effects = ["Freeze"]
	golem.resist_effects = ["Push"]
	golem.skills = [
		_skill("smash", "Ezme", "", 12, 0.0, 1.0, "Projectile", ""),
	]

	var wraith := Enemy.new()
	wraith.id = "wraith"
	wraith.display_name = "Alev Hayaleti"
	wraith.max_hp = 60
	wraith.speed = 20
	wraith.weakness_effects = ["Freeze"]
	wraith.resist_effects = ["Burn"]
	wraith.skills = [
		_skill("claw", "Pençe", "", 8, 0.0, 1.0, "Projectile", ""),
		_skill("firespit", "Alev Püskürt", "", 14, 0.0, 1.0, "Projectile", "Burn"),
	]

	return [golem, wraith]
