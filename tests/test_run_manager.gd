extends RefCounted

# Run omurgası testleri: düğüm sıralama (battle->choice->...->boss->reward), kayıp
# yolu, KİMLİK DÖNÜŞÜMÜ (Ember + Storm -> Plazma via ACQUIRE_RUNE), HP/şarj taşıma,
# orb board skoru, relic seçimi, transformed sinyali. Saf RefCounted -> sahne yok.

static func _form(id: String, name: String, base: int, with_ult := false) -> MageForm:
	var f := MageForm.new(id, name)
	f.basic_spell = Skill.new(id + "_bolt", name, "ember", base, "Projectile", "")
	if with_ult:
		var u := Skill.new(id + "_ult", name + " Ult", "ember", base * 3, "Beam", "Burn")
		u.requires_charge = true
		f.ultimate = u
	return f

# ember -> (storm) -> plasma dönüşümlü katalog.
static func _catalog() -> SkillCatalog:
	var cat := SkillCatalog.new()
	cat.add_form(_form("ember", "Ember", 20))
	cat.add_form(_form("plasma", "Plazma", 26, true))
	cat.add_transform("ember", "storm", "plasma")
	return cat

static func _party() -> Array:
	var m := Character.new()
	m.id = "ember"; m.display_name = "Kor"; m.max_hp = 90; m.speed = 14
	return [m]

static func _start(cat: SkillCatalog) -> Dictionary:
	return {"ember": cat.form("ember")}

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
	_test_transform(t)
	_test_hp_carry(t)
	_test_charge_carry(t)
	_test_generator_offers_transform(t)
	_test_content_integration(t)
	_test_orb_board_score(t)
	_test_relic_choice(t)
	_test_transformed_signal(t)
	_test_reroll_and_skip(t)

# Fizik board skorlaması: puan = Σ(orb_value × çarpan).
static func _test_orb_board_score(t) -> void:
	t.section("orb_board_score")
	t.check(OrbBoardResult.score([1.0, 2.0]) == 30, "10*(1+2)=30")
	t.check(OrbBoardResult.score([]) == 0, "boş dökülüş -> 0 puan")
	t.check(OrbBoardResult.score([0.6, 0.6, 3.0]) == 42, "10*(0.6+0.6+3.0)=42")
	t.check(OrbBoardResult.score([2.0], 25) == 50, "orb_value override 25*2=50")

# RELIC seçeneği run'a relic ekler; RelicSet hook'u taşır; sahip olunan tekrar sunulmaz.
static func _test_relic_choice(t) -> void:
	t.section("relic_choice")
	var cat := RunContent.catalog()
	t.check(cat.relics.size() >= 8, "katalog >=8 relic içerir (got %d)" % cat.relics.size())
	var rs := RunState.new(RunContent.party(), RunContent.start_forms(cat))
	var relic = cat.relics[0]
	ChoiceOption.new(ChoiceOption.Kind.RELIC, "x", {"relic": relic},
		ChoiceGenerator.cost_for(ChoiceOption.Kind.RELIC)).apply(rs)
	t.check(rs.relics.size() == 1, "relic run'a eklendi")
	t.check(rs.relic_set().has(relic.hook), "RelicSet hook taşır (%s)" % relic.hook)
	for c in ChoiceGenerator._relic_candidates(rs, cat):
		t.check(c.params["relic"].id != relic.id, "sahip olunan relic tekrar sunulmaz")

# Bir ACQUIRE_RUNE dönüşüm tetiklerse transformed emit edilir.
static func _test_transformed_signal(t) -> void:
	t.section("transformed_signal")
	var cat := _catalog()
	var rs := RunState.new(_party(), _start(cat))
	var nodes := StageDef.linear([[_enemy("a", 30)]], [_enemy("boss", 80)], 100)
	var rm := RunManager.new(cat, _rng(1))
	var got: Array = []
	rm.transformed.connect(func(f): got.append(f.id))
	rm.start(nodes, rs)
	rm.report_battle_result(true)   # -> CHOICE
	rm.current_choices = [ChoiceOption.new(ChoiceOption.Kind.ACQUIRE_RUNE, "storm",
		{"char_id": "ember", "rune_id": "storm", "form": cat.form("plasma")})]
	rm.apply_choice(0)
	t.check("plasma" in got, "storm alımı -> Plazma'ya dönüştü (transformed)")

# reroll seçenekleri yeniden üretir; skip kartsız sıradaki düğüme geçer.
static func _test_reroll_and_skip(t) -> void:
	t.section("reroll_skip")
	var cat := _catalog()
	var rs := RunState.new(_party(), _start(cat))
	var nodes := StageDef.linear([[_enemy("a", 30)], [_enemy("b", 30)]], [_enemy("boss", 80)], 100)
	var rm := RunManager.new(cat, _rng(5))
	rm.start(nodes, rs)
	rm.report_battle_result(true)   # -> CHOICE
	var idx_before: int = rs.node_index
	var emitted := {"n": 0}
	rm.choice_requested.connect(func(_o): emitted["n"] += 1)
	rm.reroll_choices()
	t.check(emitted["n"] == 1, "reroll choice_requested tekrar emit etti")
	t.check(rm.state == RunManager.State.AWAITING_CHOICE, "reroll sonrası hâlâ seçimde")
	t.check(rs.node_index == idx_before, "reroll düğümü ilerletmez")
	rm.skip_choice()
	t.check(rm.state == RunManager.State.AWAITING_BATTLE, "skip -> sıradaki savaş")

# RunContent (MVP dilim) omurgayla uçtan uca: hep kazan, mümkünse Storm al -> Plazma;
# run RUN_WON'a ulaşır, ödül yazılır. Host (battle.gd) döngüsünü sahnesiz taklit eder.
static func _test_content_integration(t) -> void:
	t.section("run_content")
	var cat := RunContent.catalog()
	var rs := RunState.new(RunContent.party(), RunContent.start_forms(cat))
	var rm := RunManager.new(cat, _rng(3))
	rm.start(RunContent.stage_nodes(0), rs)

	var guard := 0
	while rm.state != RunManager.State.RUN_WON and rm.state != RunManager.State.RUN_LOST and guard < 200:
		guard += 1
		if rm.state == RunManager.State.AWAITING_BATTLE:
			rm.report_battle_result(true)
		elif rm.state == RunManager.State.AWAITING_CHOICE:
			var pick := 0
			for i in range(rm.current_choices.size()):
				if rm.current_choices[i].kind == ChoiceOption.Kind.ACQUIRE_RUNE:
					pick = i
			rm.apply_choice(pick)

	t.check(rm.state == RunManager.State.RUN_WON, "içerik: tam run kazanıldı")
	t.check(rs.gold == RunContent.reward_gold(0), "içerik: ödül reward_gold(0) yazıldı")
	t.check(rs.loadout("ember") != null, "içerik: Ember loadout var")
	t.check(rs.loadout("ember").current_form.id == "plasma", "içerik: Storm alınıp Plazma'ya dönüştü")

# Tam akış: 2 normal savaş (arada seçim) -> boss -> reward -> RUN_WON + para.
static func _test_full_sequence(t) -> void:
	t.section("run_full_sequence")
	var cat := _catalog()
	var rs := RunState.new(_party(), _start(cat))
	var battles := [[_enemy("a", 30)], [_enemy("b", 30)]]
	var nodes := StageDef.linear(battles, [_enemy("boss", 80)], 100)
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
	var cat := _catalog()
	var rs := RunState.new(_party(), _start(cat))
	var nodes := StageDef.linear([[_enemy("a", 30)]], [_enemy("boss", 80)], 100)
	var rm := RunManager.new(cat, _rng(1))
	rm.start(nodes, rs)
	rm.report_battle_result(false)
	t.check(rm.state == RunManager.State.RUN_LOST, "kayıp -> RUN_LOST")
	t.check(rs.gold == 0, "kaybedince ödül yok")

# ACQUIRE_RUNE formu dönüştürür; becerileri yeni forma göre gelir.
static func _test_transform(t) -> void:
	t.section("run_transform")
	var cat := _catalog()
	var rs := RunState.new(_party(), _start(cat))
	var lo := rs.loadout("ember")
	t.check(lo.current_form.id == "ember", "başta Ember formu")
	t.check(lo.available_skills().size() == 1, "Ember: sadece temel büyü")
	t.check(not _has_skill(lo.available_skills(), "plasma_ult"), "Ember'de Plazma ultimate yok")

	var opt := ChoiceOption.new(ChoiceOption.Kind.ACQUIRE_RUNE, "storm",
		{"char_id": "ember", "rune_id": "storm", "form": cat.form("plasma")})
	opt.apply(rs)
	t.check(lo.current_form.id == "plasma", "Storm alınınca Plazma'ya dönüştü")
	t.check(_has_skill(lo.available_skills(), "plasma_ult"), "Plazma: temel + ultimate")
	t.check(lo.available_skills().size() == 2, "Plazma 2 beceri (temel + ultimate)")

# HP savaşlar arası taşınır; heal/max HP seçenekleri uygulanır.
static func _test_hp_carry(t) -> void:
	t.section("run_hp_carry")
	var cat := _catalog()
	var rs := RunState.new(_party(), _start(cat))
	var lo := rs.loadout("ember")
	t.check(lo.current_hp == 90, "run başı tam can")
	lo.current_hp = 40
	ChoiceOption.new(ChoiceOption.Kind.HEAL, "heal", {"char_id": "", "amount": 25}).apply(rs)
	t.check(lo.current_hp == 65, "heal parti geneli (+25)")
	ChoiceOption.new(ChoiceOption.Kind.MAX_HP, "hp", {"char_id": "ember", "amount": 20}).apply(rs)
	t.check(lo.max_hp() == 110, "max HP +20")
	lo.heal(1000)
	t.check(lo.current_hp == 110, "heal tavanı max HP")

# Şarj savaşlar arası taşınır ama geçişte %20 düşer (store_charge).
static func _test_charge_carry(t) -> void:
	t.section("run_charge_carry")
	var cat := _catalog()
	var rs := RunState.new(_party(), _start(cat))
	var lo := rs.loadout("ember")
	t.check(lo.charge == 0, "run başı şarj 0")
	lo.store_charge(100, 0.20)
	t.check(lo.charge == 80, "wave sonu 100 -> 80 (%20 düşer)")
	lo.store_charge(lo.charge, 0.20)
	t.check(lo.charge == 64, "bir sonraki wave 80 -> 64 (bileşik)")
	lo.store_charge(0, 0.20)
	t.check(lo.charge == 0, "0 -> 0 (asla negatif)")

# Seçim üretici deterministik ve dönüşüm mümkünse bir ACQUIRE_RUNE sunar.
static func _test_generator_offers_transform(t) -> void:
	t.section("choice_generator")
	var cat := _catalog()
	var rs := RunState.new(_party(), _start(cat))
	var opts := ChoiceGenerator.generate(rs, cat, _rng(7))
	t.check(opts.size() == 3, "3 seçenek üretir")
	var has_transform := false
	for o in opts:
		if o.kind == ChoiceOption.Kind.ACQUIRE_RUNE:
			has_transform = true
	t.check(has_transform, "en az bir dönüşüm (rün alma) sunulur")
	var opts2 := ChoiceGenerator.generate(rs, cat, _rng(7))
	t.check(opts[0].label == opts2[0].label, "aynı seed aynı sonuç")

static func _has_skill(skills: Array, id: String) -> bool:
	for s in skills:
		if s.id == id:
			return true
	return false
