extends RefCounted
class_name RunContent

# Demo run içeriği — TestBattleData'nın RUN karşılığı. Saf/headless. Bir bölümün
# beceri kataloğu + parti (temel rünle) + düğüm listesini kodla kurar (sahne/.tres
# gerekmez). Rün-draft modeli: normaller rune_id ile paylaşılır (her büyücü her
# rünü draft edebilir), birleşimler kaynak çifti tamamlanınca açılır.
#   ember+storm -> Plazma (yakma), frost+gale -> Fırtına (stun).

static func _skill(id: String, name: String, rune: String, base: int,
		limit: float, bonus: float, carrier: String, effect: String) -> Skill:
	return Skill.new(id, name, rune, base, limit, bonus, carrier, effect)

# --- Beceri kataloğu (draft havuzu + birleşimler) ---
static func catalog() -> SkillCatalog:
	var cat := SkillCatalog.new()
	cat.add_normal(_skill("fireball", "Alev Topu", "ember", 20, 2.0, 1.5, "Projectile", "Burn"))
	cat.add_normal(_skill("shatterwave", "Kırılma Dalgası", "storm", 24, 1.6, 1.4, "Area", "Shatter"))
	cat.add_normal(_skill("frostbite", "Buz Isırığı", "frost", 18, 1.8, 1.6, "Cone", "Freeze"))
	cat.add_normal(_skill("gust", "Rüzgar", "gale", 15, 2.2, 1.5, "Wave", "Push"))

	var plasma := _skill("plasma", "Plazma", "", 44, 2.0, 2.5, "Beam", "Burn")
	plasma.requires_charge = true
	plasma.rune_sequence = ["ember", "storm"]
	plasma.dot_fraction = 0.40
	cat.add_combo(plasma)

	var tempest := _skill("tempest", "Fırtına", "", 33, 1.8, 2.5, "Storm", "Freeze")
	tempest.requires_charge = true
	tempest.rune_sequence = ["frost", "gale"]
	tempest.applies_stun = true
	cat.add_combo(tempest)
	return cat

# --- Parti (skills BOŞ — rünler draft edilir) ---
static func party() -> Array:
	var kayra := Character.new()
	kayra.id = "kayra"; kayra.display_name = "Kayra"
	kayra.element_pair = ["Ateş", "Yıldırım"]; kayra.max_hp = 90; kayra.speed = 14

	var derin := Character.new()
	derin.id = "derin"; derin.display_name = "Derin"
	derin.element_pair = ["Su", "Rüzgar"]; derin.max_hp = 70; derin.speed = 18
	return [kayra, derin]

# Bölüm başı temel kit: her büyücü bir rünle başlar, gerisini draft eder.
static func base_runes() -> Dictionary:
	return {"kayra": ["ember"], "derin": ["frost"]}

# --- Seviyeler: her biri [BATTLE,CHOICE]×2 -> BOSS -> REWARD, zorluk ölçekli ---
# Düşman HP + hasarı seviyeyle büyür (scale = 1 + 0.30*i). Ödül de artar.
const LEVEL_COUNT := 5

static func level_count() -> int:
	return LEVEL_COUNT

static func level_name(i: int) -> String:
	return "Seviye %d" % (i + 1)

static func reward_gold(i: int) -> int:
	return 80 + 40 * i

static func reward_crystal(_i: int) -> int:
	return 1   # her bölüm bitişi 1 kristal (nadir)

# i. seviyenin düğüm listesi. Ölçek HP + düşman hasarına uygulanır.
static func stage_nodes(i: int) -> Array:
	var s := 1.0 + 0.30 * i
	return StageDef.linear([_battle_1(s), _battle_2(s)], _boss(s), reward_gold(i))

static func _enemy(id: String, ename: String, hp: int, speed: int,
		weak: Array[String], resist: Array[String], attacks: Array[Skill]) -> Enemy:
	var e := Enemy.new()
	e.id = id; e.display_name = ename; e.max_hp = hp; e.speed = speed
	e.weakness_effects = weak; e.resist_effects = resist; e.skills = attacks
	return e

static func _atk(id: String, name: String, dmg: int, carrier: String, effect: String, s: float) -> Skill:
	return _skill(id, name, "", int(round(dmg * s)), 0.0, 1.0, carrier, effect)

static func _hp(base: int, s: float) -> int:
	return int(round(base * s))

static func _battle_1(s: float) -> Array:
	return [_enemy("goblin", "Goblin", _hp(45, s), 12, ["Burn"], [],
		[_atk("slash", "Kesik", 8, "Projectile", "", s)])]

static func _battle_2(s: float) -> Array:
	return [
		_enemy("golem", "Taş Golem", _hp(75, s), 8, ["Freeze"], ["Push"],
			[_atk("smash", "Ezme", 12, "Projectile", "", s)]),
		_enemy("wraith", "Alev Hayaleti", _hp(50, s), 20, ["Freeze"], ["Burn"],
			[_atk("claw", "Pençe", 8, "Projectile", "", s)]),
	]

static func _boss(s: float) -> Array:
	return [_enemy("boss", "Kül Ejderi", _hp(180, s), 16, ["Freeze"], ["Burn"],
		[_atk("firebreath", "Alev Nefesi", 18, "Area", "Burn", s)])]
