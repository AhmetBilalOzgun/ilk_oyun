extends RefCounted

static func run(t) -> void:
	t.section("elemental-archetype-transition")
	var cat := RunContent.catalog()
	var run := RunState.new(RunContent.party(), RunContent.start_forms(cat))
	var lo := run.loadout("ember")
	lo.add_archetype(RunContent.ember_archetypes()[0])
	lo.acquire_rune("storm", cat)
	t.check(lo.current_form.id == "plasma", "rune transforms the mage")
	t.check(lo.archetypes[0].form_id == "plasma", "family adapts to plasma")
	t.eqf(run.relic_set().amount("enemy_miss_chance", 0), 0.35, "blind chance is exactly 35 percent")
	t.check(not run.relic_set().has("burn_spread"), "blind plasma does not retain obsolete burn effects")
	t.check(GameLook.form_key(lo) == "plasma_blind", "blind visuals agree with mechanics")
	t.check(ChoiceGenerator._archetype_candidates(run, cat).is_empty(), "transformation preserves exclusive commitment")
	var keys := {}
	for form in [cat.form("ember"), cat.form("plasma")]:
		var preview := RunLoadout.new(RunContent.party()[0], form)
		keys[GameLook.form_key(preview)] = true
		for a in cat.archetypes_for(form.id):
			preview.archetypes = [a]
			keys[GameLook.form_key(preview)] = true
	t.check(keys.size() == 8, "eight distinct art bindings")
	for key in keys:
		var frames := GameLook.frames(key)
		t.check(frames != null, "frames available: " + key)
		for anim in ["idle", "cast", "hurt", "death", "victory", "ult"]:
			t.check(frames.has_animation(anim) and frames.get_frame_count(anim) >= 3, key + " / " + anim)
	for i in range(20):
		t.check(GameLook.world_index(i) == i / 4, "four stages per world")
	for i in range(5):
		t.check(GameLook.backdrop(i) != null, "world asset loaded")

	t.section("blind-prevents-complete-enemy-action")
	var hero := Character.new()
	hero.id = "hero"; hero.max_hp = 100; hero.speed = 10
	var foe := Enemy.new()
	foe.id = "foe"; foe.max_hp = 100; foe.speed = 1
	var attack := Skill.new("test", "test", "", 10, "Area", "")
	attack.aoe = true
	attack.dot_fraction = 0.5
	attack.applies_stun = true
	foe.skills = [attack]
	var rs := RelicSet.new()
	rs.add(Relic.new("blind", "", "", "enemy_miss_chance", 0.35))
	rs.add(Relic.new("reflect", "", "", "reflect", 0.5))
	var tm := TurnManager.new(BattleConfig.new(), rs)
	tm.combat_rng.seed = 92841
	tm.start_battle([hero], [foe])
	var target: Combatant = tm.combatants[0]
	var enemy: Combatant = tm.combatants[1]
	tm.active = enemy
	var misses := 0
	for i in range(1000):
		target.hp = 100; enemy.hp = 100
		target.pending_dot = 0; target.stunned = false
		target.charge = 0; enemy.charge = 0
		tm._apply_action(attack, target, 1.0, 0.0)
		if tm.last_breakdown.missed:
			misses += 1
			t.check(target.hp == 100 and enemy.hp == 100, "miss has no damage or reflect")
			t.check(target.pending_dot == 0 and not target.stunned, "miss has no status")
			t.check(target.charge == 0 and enemy.charge == 0, "miss gives no charge")
		else:
			t.check(target.hp == 90, "non-miss still deals full damage")
	t.check(misses > 290 and misses < 410, "seeded miss distribution near 35 percent: %d" % misses)
	# Defensive hook must never cancel player attacks.
	tm.active = target
	enemy.hp = 100
	tm._apply_action(attack, enemy, 1.0, 0.0)
	t.check(not tm.last_breakdown.missed and enemy.hp == 90, "player fail-soft damage remains intact")
