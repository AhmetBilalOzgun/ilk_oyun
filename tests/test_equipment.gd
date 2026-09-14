extends RefCounted

# Ekipman testleri: katalog, meta al/tak/kaydet, savaş hook'ları (burn/shatter amp,
# reflect, hız/hp bonusu). Relic ile aynı hook desenini paylaşır.

static func _meta() -> MetaProgress:
	var m := MetaProgress.new()
	m.persist = false   # test: diske yazma/okuma yok
	return m

static func _typed(skills: Array) -> Array[Skill]:
	var out: Array[Skill] = []
	for s in skills:
		out.append(s)
	return out

static func run(t) -> void:
	t.section("equipment_catalog")
	var cat := Equipment.catalog()
	t.check(cat.size() >= 9, ">=9 ekipman (got %d)" % cat.size())
	var slots := {0: 0, 1: 0, 2: 0}
	for e in cat:
		slots[e.slot] += 1
	t.check(slots[0] >= 3 and slots[1] >= 3 and slots[2] >= 3, "her slot >=3 parça")
	t.check(Equipment.by_id("flame_armor") != null, "by_id bulur")
	t.check(Equipment.by_id("yok") == null, "olmayan id -> null")

	t.section("equipment_meta")
	var m := _meta()
	m.gold = 200
	t.check(not m.is_owned("flame_armor"), "başta sahip değil")
	t.check(m.buy_equipment("flame_armor", 150), "150 altınla alındı")
	t.check(m.gold == 50, "altın düştü (200-150)")
	t.check(m.is_owned("flame_armor"), "sahip oldu")
	t.check(not m.buy_equipment("flame_armor", 150), "aynısı tekrar alınamaz")
	t.check(not m.buy_equipment("plate_armor", 160), "yeter altın yok -> alınamaz")
	t.check(m.equip(Equipment.by_id("flame_armor")), "takıldı")
	t.check(m.equipped_in(Equipment.Slot.ARMOR) == "flame_armor", "ARMOR slotunda flame_armor")
	# Aynı slota başka parça takınca değişir.
	m.gold = 200
	m.buy_equipment("thorn_armor", 130)
	m.equip(Equipment.by_id("thorn_armor"))
	t.check(m.equipped_in(Equipment.Slot.ARMOR) == "thorn_armor", "ARMOR slotu değişti")

	# Düz stat bonusları.
	m.gold = 500
	m.buy_equipment("swift_boots", 110); m.equip(Equipment.by_id("swift_boots"))
	m.buy_equipment("vital_helm", 100); m.equip(Equipment.by_id("vital_helm"))
	t.check(m.equipped_speed_bonus() == 6, "swift_boots +6 hız (got %d)" % m.equipped_speed_bonus())
	t.check(m.equipped_hp_bonus() == 30, "vital_helm +30 hp; thorn zırhı hp vermez (got %d)" % m.equipped_hp_bonus())

	t.section("equipment_hooks")
	var cfg := BattleConfig.new()
	var foe := Enemy.new(); foe.max_hp = 100
	var fc := Combatant.new(Combatant.Side.ENEMY, foe)
	# burn_dmg_amp (Alev Zırhı 1.4)
	var rs := RelicSet.new(); rs.add(Equipment.by_id("flame_armor"))
	var burn := Skill.new("b", "b", "ember", 20, "Projectile", "Burn")
	t.eqf(float(BattleDamage.compute(burn, 1.0, fc, cfg, rs).final_damage), 28.0, "burn_dmg_amp 20*1.4=28")
	# shatter_dmg_amp (İletken Başlık 1.35)
	var rs2 := RelicSet.new(); rs2.add(Equipment.by_id("cond_helm"))
	var shatter := Skill.new("s", "s", "storm", 20, "Beam", "Shatter")
	t.eqf(float(BattleDamage.compute(shatter, 1.0, fc, cfg, rs2).final_damage), 27.0, "shatter_dmg_amp 20*1.35=27")
	# Eşleşmeyen effect etkilenmez (Alev Zırhı Shatter'ı artırmaz).
	t.eqf(float(BattleDamage.compute(shatter, 1.0, fc, cfg, rs).final_damage), 20.0, "flame armor shatter'ı etkilemez")

	# reflect (Diken Zırhı 0.15): düşman vurunca saldırgan hasar alır.
	t.section("equipment_reflect")
	var rs3 := RelicSet.new(); rs3.add(Equipment.by_id("thorn_armor"))
	var hero := Character.new(); hero.id = "h"; hero.max_hp = 100; hero.speed = 1
	hero.skills = _typed([Skill.new("x", "x", "", 1, "Projectile", "")])
	var en := Enemy.new(); en.id = "e"; en.max_hp = 100; en.speed = 50
	en.skills = _typed([Skill.new("hit", "hit", "", 20, "Projectile", "")])
	var tm := TurnManager.new(cfg, rs3)
	tm.start_battle([hero], [en])   # düşman hızlı -> ilk vurur, reflect tetiklenir
	var enemy_c: Combatant = tm._alive_on(Combatant.Side.ENEMY)[0]
	t.check(enemy_c.hp == 100 - 3, "reflect: saldırgan 20*0.15=3 hasar aldı (got %d)" % enemy_c.hp)
