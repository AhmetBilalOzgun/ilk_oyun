extends RefCounted

# Run omurgası testleri: düğüm sıralama (battle->choice->...->boss->reward),
# kayıp yolu, rün draftı kiti büyütür, birleşim (combo) kaynak çifti tamamlanınca
# OTOMATİK açılır, HP savaşlar arası taşınır. Saf RefCounted -> sahne gerekmez.

static func _skill(id: String, rune: String, base: int) -> Skill:
	return Skill.new(id, id, rune, base, 2.0, 1.5, "Projectile", "")

# ember/storm/frost/gale normal + plasma(ember,storm) & tempest(frost,gale) combo.
static func _catalog() -> SkillCatalog:
	var cat := SkillCatalog.new()
	cat.add_normal(_skill("fireball", "ember", 20))
	cat.add_normal(_skill("shatter", "storm", 22))
	cat.add_normal(_skill("frostbite", "frost", 18))
	cat.add_normal(_skill("gust", "gale", 15))

	var plasma := Skill.new("plasma", "Plazma", "", 44, 2.0, 2.5, "Beam", "Burn")
	plasma.requires_charge = true
	plasma.rune_sequence = ["ember", "storm"]
	cat.add_combo(plasma)

	var tempest := Skill.new("tempest", "Fırtına", "", 33, 2.0, 2.5, "Storm", "Freeze")
	tempest.requires_charge = true
	tempest.rune_sequence = ["frost", "gale"]
	cat.add_combo(tempest)
	return cat

static func _party() -> Array:
	var kayra := Character.new()
	kayra.id = "kayra"; kayra.display_name = "Kayra"; kayra.max_hp = 90; kayra.speed = 14
	var derin := Character.new()
	derin.id = "derin"; derin.display_name = "Derin"; derin.max_hp = 70; derin.speed = 18
	return [kayra, derin]

static func _enemy(id: String, hp: int) -> Enemy:
	var e := Enemy.new()
	e.id = id; e.display_name = id; e.max_hp = hp; e.speed = 5
	return e

static func _rng(seed: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	return r

static func run(t) -> void:
	_test_full_sequence(t)
	_test_loss_path(t)
	_test_draft_and_combo(t)
	_test_hp_carry(t)
	_test_generator_offers_drafts(t)
	_test_content_integration(t)

# RunContent (demo bölüm) omurgayla uçtan uca: hep kazan, Kayra'ya storm draft
# edilebildiğinde seç -> run RUN_WON'a ulaşır, ödül yazılır, Plazma açılır.
# Host (battle.gd) döngüsünü sahnesiz taklit eder -> içerik tutarlılığını kanıtlar.
static func _test_content_integration(t) -> void:
	t.section("run_content")
	var cat := RunContent.catalog()
	var rs := RunState.new(RunContent.party(), RunContent.base_runes())
	var rm := RunManager.new(cat, _rng(3))
	rm.start(RunContent.stage_nodes(0), rs)

	var guard := 0
	while rm.state != RunManager.State.RUN_WON and rm.state != RunManager.State.RUN_LOST and guard < 100:
		guard += 1
		if rm.state == RunManager.State.AWAITING_BATTLE:
			rm.report_battle_result(true)
		elif rm.state == RunManager.State.AWAITING_CHOICE:
			var pick := 0
			for i in range(rm.current_choices.size()):
				var o: ChoiceOption = rm.current_choices[i]
				if o.kind == ChoiceOption.Kind.DRAFT_RUNE \
						and o.params.get("char_id") == "kayra" \
						and o.params.get("rune_id") == "storm":
					pick = i
			rm.apply_choice(pick)

	t.check(rm.state == RunManager.State.RUN_WON, "içerik: tam run kazanıldı")
	t.check(rs.gold == RunContent.reward_gold(0), "içerik: ödül reward_gold(0) yazıldı")
	t.check(rs.loadout("kayra") != null, "içerik: Kayra loadout var")

# Tam akış: 2 normal savaş (arada seçim) -> boss -> reward -> RUN_WON + para.
static func _test_full_sequence(t) -> void:
	t.section("run_full_sequence")
	var cat := _catalog()
	var rs := RunState.new(_party(), {"kayra": ["ember"], "derin": ["frost"]})
	var battles := [[_enemy("a", 30)], [_enemy("b", 30)]]
	var nodes := StageDef.linear(battles, [_enemy("boss", 80)], 100)
	# [B,C,B,C,BOSS,REWARD] = 6 düğüm
	t.check(nodes.size() == 6, "linear 6 düğüm üretir")

	var rm := RunManager.new(cat, _rng(1))
	rm.start(nodes, rs)

	t.check(rm.state == RunManager.State.AWAITING_BATTLE, "1. savaş bekleniyor")
	rm.report_battle_result(true)
	t.check(rm.state == RunManager.State.AWAITING_CHOICE, "savaş sonrası seçim")
	rm.apply_choice(0)
	t.check(rm.state == RunManager.State.AWAITING_BATTLE, "2. savaş bekleniyor")
	rm.report_battle_result(true)
	rm.apply_choice(0)
	t.check(rm.current_node().type == RunNode.Type.BOSS, "boss düğümü aktif")
	rm.report_battle_result(true)
	t.check(rm.state == RunManager.State.RUN_WON, "boss sonrası RUN_WON")
	t.check(rs.gold == 100, "reward parayı yazdı")

# İlk savaş kaybı -> RUN_LOST, ilerleme yok.
static func _test_loss_path(t) -> void:
	t.section("run_loss")
	var rs := RunState.new(_party(), {})
	var nodes := StageDef.linear([[_enemy("a", 30)]], [_enemy("boss", 80)], 100)
	var rm := RunManager.new(_catalog(), _rng(1))
	rm.start(nodes, rs)
	rm.report_battle_result(false)
	t.check(rm.state == RunManager.State.RUN_LOST, "kayıp -> RUN_LOST")
	t.check(rs.gold == 0, "kaybedince ödül yok")

# Draft rün ekler; kaynak çifti tamamlanınca combo OTOMATİK available olur.
static func _test_draft_and_combo(t) -> void:
	t.section("run_draft_combo")
	var cat := _catalog()
	var rs := RunState.new(_party(), {"kayra": ["ember"], "derin": ["frost"]})
	var kayra := rs.loadout("kayra")

	# Başta sadece ember -> 1 normal beceri, combo yok.
	var before := kayra.available_skills(cat)
	t.check(before.size() == 1, "ember tek beceri verir")
	t.check(not _has_skill(before, "plasma"), "tek rünle Plazma kapalı")

	# storm draft et -> ember+storm = Plazma açılır.
	var opt := ChoiceOption.new(ChoiceOption.Kind.DRAFT_RUNE, "storm",
		{"char_id": "kayra", "rune_id": "storm"})
	opt.apply(rs)
	t.check(kayra.has_rune("storm"), "storm kite eklendi")
	var after := kayra.available_skills(cat)
	t.check(_has_skill(after, "plasma"), "ember+storm -> Plazma AÇILDI")
	t.check(after.size() == 3, "2 normal + 1 combo = 3 beceri")
	# Derin'in çifti hâlâ eksik -> Fırtına kapalı.
	t.check(not _has_skill(rs.loadout("derin").available_skills(cat), "tempest"),
		"Derin yarım çiftle Fırtına kapalı")

# HP savaşlar arası taşınır; heal/max HP seçenekleri uygulanır.
static func _test_hp_carry(t) -> void:
	t.section("run_hp_carry")
	var rs := RunState.new(_party(), {})
	var kayra := rs.loadout("kayra")
	t.check(kayra.current_hp == 90, "run başı tam can")
	kayra.current_hp = 40
	ChoiceOption.new(ChoiceOption.Kind.HEAL, "heal", {"char_id": "", "amount": 25}).apply(rs)
	t.check(kayra.current_hp == 65, "heal parti geneli (+25)")
	ChoiceOption.new(ChoiceOption.Kind.MAX_HP, "hp", {"char_id": "kayra", "amount": 20}).apply(rs)
	t.check(kayra.max_hp() == 110, "max HP +20")
	# Heal tavanı max_hp'yi aşmaz.
	kayra.heal(1000)
	t.check(kayra.current_hp == 110, "heal tavanı max HP")

# Seçim üretici deterministik ve en az bir rün draftı sunar.
static func _test_generator_offers_drafts(t) -> void:
	t.section("choice_generator")
	var cat := _catalog()
	var rs := RunState.new(_party(), {})
	var opts := ChoiceGenerator.generate(rs, cat, _rng(7))
	t.check(opts.size() == 3, "3 seçenek üretir")
	var has_draft := false
	for o in opts:
		if o.kind == ChoiceOption.Kind.DRAFT_RUNE:
			has_draft = true
	t.check(has_draft, "en az bir rün draftı sunulur")
	# Aynı seed -> aynı ilk seçenek (determinizm).
	var opts2 := ChoiceGenerator.generate(rs, cat, _rng(7))
	t.check(opts[0].label == opts2[0].label, "aynı seed aynı sonuç")

static func _has_skill(skills: Array, id: String) -> bool:
	for s in skills:
		if s.id == id:
			return true
	return false
