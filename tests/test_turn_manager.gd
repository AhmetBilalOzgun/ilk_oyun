extends RefCounted

# Turn-based savaş testleri: sıra hesaplama, aktif girdi çarpanı (fail-soft),
# zaaf/direnç (asla 0), şarj barı, ULTIMATE + DoT/stun/AoE, relic hook'ları.
# Çekirdek saf RefCounted -> sahne gerekmez. Çizim/QTE KALDIRILDI; yerine
# select_action -> submit_input(result) iki adımlı aktif girdi (bkz TurnManager).

const R := InputEvaluator.Result   # R.MISS / R.GOOD / R.PERFECT

static func _cfg() -> BattleConfig:
	var c := BattleConfig.new()
	c.weakness_multiplier = 1.5
	c.resist_multiplier = 0.5
	return c

static func _char(id: String, hp: int, speed: int, skills: Array) -> Character:
	var c := Character.new()
	c.id = id; c.display_name = id; c.max_hp = hp; c.speed = speed
	var typed: Array[Skill] = []
	for s in skills:
		typed.append(s)
	c.skills = typed
	return c

static func _foe(id: String, hp: int, speed: int, weak: Array[String], skills: Array) -> Enemy:
	var e := Enemy.new()
	e.id = id; e.display_name = id; e.max_hp = hp; e.speed = speed
	e.weakness_effects = weak
	var typed: Array[Skill] = []
	for s in skills:
		typed.append(s)
	e.skills = typed
	return e

static func _bite() -> Skill:
	return Skill.new("bite", "Isır", "", 7, "Projectile", "")

# Oyuncu önce (yüksek speed), tek bolt (Burn) + Burn-zaaflı foe.
static func _duel() -> Dictionary:
	var bolt := Skill.new("bolt", "Ok", "ember", 20, "Projectile", "Burn")
	var hero := _char("hero", 100, 50, [bolt])
	var foe := _foe("foe", 200, 1, ["Burn"], [_bite()])
	var tm := TurnManager.new(_cfg())
	tm.start_battle([hero], [foe])
	return {"tm": tm, "hero": tm.active, "foe": tm._alive_on(Combatant.Side.ENEMY)[0], "bolt": bolt}

# hero (bolt + ultimate), tek yavaş foe (Burn zaafı, yüksek HP).
static func _ult_setup(charge_max: int, ult: Skill, foe_hp := 500, relics: RelicSet = null) -> Dictionary:
	var bolt := Skill.new("bolt", "Ok", "ember", 20, "Projectile", "Burn")
	var hero := _char("h", 300, 50, [bolt, ult])
	var foe := _foe("f", foe_hp, 1, ["Burn"], [_bite()])
	var cfg := _cfg()
	cfg.charge_max = charge_max
	var tm := TurnManager.new(cfg, relics)
	tm.start_battle([hero], [foe])
	return {"tm": tm, "hero": tm.active, "foe": tm._alive_on(Combatant.Side.ENEMY)[0], "bolt": bolt, "ult": ult}

# Bir oyuncu eylemini tamamla: seç + girdi sonucu ver.
static func _act(tm: TurnManager, skill: Skill, target: Combatant, result: int) -> void:
	tm.select_action(skill, target)
	tm.submit_input(result)

# Kombo yolu: seç + float çarpan ver (RhythmMinigame combo_score -> mult).
static func _act_mult(tm: TurnManager, skill: Skill, target: Combatant, mult: float, quality: float) -> void:
	tm.select_action(skill, target)
	tm.submit_input_multiplier(mult, quality)

static func run(t) -> void:
	# --- Sıra hesaplama: speed azalan, stabil ---
	t.section("sıra-hesaplama")
	var tmS := TurnManager.new(_cfg())
	tmS.start_battle(
		[_char("a", 100, 14, [_bite()]), _char("b", 100, 18, [_bite()])],
		[_foe("g", 100, 8, [], [_bite()]), _foe("w", 100, 20, [], [_bite()])])
	var speeds: Array = []
	for c in tmS.order:
		speeds.append(c.speed())
	t.check(speeds == [20, 18, 14, 8], "sıra speed'e göre azalan (got %s)" % [speeds])
	t.check(tmS.order[0].display_name() == "w", "en hızlı (20) ilk sırada")

	# --- Aktif girdi: seç -> AWAITING_INPUT -> submit çözer ---
	t.section("aktif-girdi")
	var d := _duel()
	var tm2: TurnManager = d["tm"]
	t.check(tm2.state == TurnManager.State.SELECTING_ACTION, "oyuncu sırası açıldı")
	tm2.select_action(d["bolt"], d["foe"])
	t.check(tm2.state == TurnManager.State.AWAITING_INPUT, "seçince girdi bekliyor")
	tm2.submit_input(R.PERFECT)
	t.check(tm2.state == TurnManager.State.NEXT_TURN, "girdi verilince çözüldü")
	var b: DamageBreakdown = tm2.last_breakdown
	# base 20 * PERFECT 1.5 = 30, sonra zaaf (Burn) *1.5 = 45
	t.check(b.input_success, "PERFECT çarpanı uygulandı (>1)")
	t.eqf(float(b.after_bonus), 30.0, "PERFECT sonrası 20*1.5=30")
	t.eqf(float(b.final_damage), 45.0, "nihai 30*1.5=45")
	t.check(d["foe"].hp == 200 - 45, "hedef gerçekten hasar aldı")

	# --- Fail-soft: MISS bile taban hasar verir ---
	t.section("fail-soft-miss")
	var dm := _duel()
	var tmM: TurnManager = dm["tm"]
	_act(tmM, dm["bolt"], dm["foe"], R.MISS)
	var bm: DamageBreakdown = tmM.last_breakdown
	t.eqf(float(bm.after_bonus), 20.0, "MISS -> taban 20 (çarpan 1.0)")
	t.eqf(float(bm.final_damage), 30.0, "MISS taban * zaaf 1.5 = 30 (büyü iptal olmadı)")
	# GOOD ara değer
	var dg := _duel()
	_act(dg["tm"], dg["bolt"], dg["foe"], R.GOOD)
	t.eqf(float(dg["tm"].last_breakdown.after_bonus), 25.0, "GOOD -> 20*1.25=25")

	# --- Kombo yolu: submit_input_multiplier (float çarpan, RhythmMinigame kombosu) ---
	t.section("kombo-çarpan")
	# Tümü PERFECT kombo eşdeğeri: mult=perfect_multiplier -> enum PERFECT ile aynı hasar.
	var dc := _duel()
	var tmC: TurnManager = dc["tm"]
	tmC.select_action(dc["bolt"], dc["foe"])
	t.check(tmC.state == TurnManager.State.AWAITING_INPUT, "kombo: girdi bekliyor")
	tmC.submit_input_multiplier(tmC.config.perfect_multiplier, 1.0)
	t.check(tmC.state == TurnManager.State.NEXT_TURN, "kombo: çarpan verilince çözüldü")
	var bcm: DamageBreakdown = tmC.last_breakdown
	t.eqf(float(bcm.after_bonus), 30.0, "kombo PERFECT eşdeğeri 20*1.5=30")
	t.eqf(float(bcm.final_damage), 45.0, "kombo nihai 30*1.5=45")
	t.eqf(bcm.input_quality, 1.0, "quality iletildi (1.0)")
	# Kombo kırıldı / floor: mult=miss_multiplier -> taban hasar (fail-soft korunur).
	var dc2 := _duel()
	_act_mult(dc2["tm"], dc2["bolt"], dc2["foe"], dc2["tm"].config.miss_multiplier, 0.0)
	t.eqf(float(dc2["tm"].last_breakdown.after_bonus), 20.0, "kombo floor -> taban 20 (×1.0)")
	t.eqf(float(dc2["tm"].last_breakdown.final_damage), 30.0, "floor taban * zaaf 1.5 = 30")
	# Kısmi kombo: mult ara değer -> ara hasar.
	var dc3 := _duel()
	_act_mult(dc3["tm"], dc3["bolt"], dc3["foe"], 1.2, 0.4)
	t.eqf(float(dc3["tm"].last_breakdown.after_bonus), 24.0, "kısmi kombo 20*1.2=24")

	# --- Zaaf / direnç çarpanları, hiçbir zaman sıfır ---
	t.section("zaaf-direnç")
	var cfg := _cfg()
	var sk := Skill.new("f", "f", "ember", 20, "Projectile", "Burn")
	var weak := Enemy.new(); weak.max_hp = 100; weak.weakness_effects = ["Burn"]
	var wc := Combatant.new(Combatant.Side.ENEMY, weak)
	t.eqf(float(BattleDamage.compute(sk, 1.0, wc, cfg).final_damage), 30.0, "zaaf: 20*1.5=30")
	var res := Enemy.new(); res.max_hp = 100; res.resist_effects = ["Burn"]
	var rc := Combatant.new(Combatant.Side.ENEMY, res)
	var br := BattleDamage.compute(sk, 1.0, rc, cfg)
	t.eqf(float(br.final_damage), 10.0, "direnç: 20*0.5=10")
	t.check(br.final_damage > 0, "direnç hasarı sıfırlamaz")
	var tiny := Skill.new("t", "t", "gale", 1, "Wave", "Push")
	var res2 := Enemy.new(); res2.max_hp = 100; res2.resist_effects = ["Push"]
	var rc2 := Combatant.new(Combatant.Side.ENEMY, res2)
	t.check(BattleDamage.compute(tiny, 1.0, rc2, cfg).final_damage >= 1, "min 1 hasar tabanı")

	# --- Tam savaş: bir taraf elenince battle_ended + combatant_defeated ---
	t.section("savaş-sonu")
	var d5 := _duel()
	var tm5: TurnManager = d5["tm"]
	var ended := {"winner": -1}
	var defeated := {"n": 0}
	tm5.battle_ended.connect(func(w): ended["winner"] = w)
	tm5.combatant_defeated.connect(func(_c): defeated["n"] += 1)
	var guard := 0
	while tm5.state != TurnManager.State.BATTLE_OVER and guard < 200:
		guard += 1
		if tm5.state == TurnManager.State.SELECTING_ACTION:
			_act(tm5, tm5.active.skills()[0], tm5._alive_on(Combatant.Side.ENEMY)[0], R.PERFECT)
		elif tm5.state == TurnManager.State.NEXT_TURN:
			tm5.advance_turn()
		else:
			break
	t.check(tm5.state == TurnManager.State.BATTLE_OVER, "savaş bitti")
	t.check(ended["winner"] == Combatant.Side.PARTY, "parti kazandı")
	t.check(defeated["n"] == 1, "combatant_defeated bir kez (got %d)" % defeated["n"])

	# --- Şarj barı: verilen + alınan hasar kadar dolar ---
	t.section("şarj-dolumu")
	var ultA := _mk_ult("plasma", 44, "Burn", 0.40, false, false)
	var s := _ult_setup(1000, ultA)
	_act(s["tm"], s["bolt"], s["foe"], R.PERFECT)   # 20*1.5=30, zaaf *1.5=45
	t.check(s["hero"].charge == 45, "vuran verilen hasar kadar şarj (got %d)" % s["hero"].charge)
	t.check(s["foe"].charge == 45, "yiyen alınan hasar kadar şarj (got %d)" % s["foe"].charge)

	# --- Ultimate kilidi: şarj dolu değilse seçilemez ---
	t.section("ultimate-kilit")
	var ultB := _mk_ult("plasma", 44, "Burn", 0.40, false, false)
	var s2 := _ult_setup(40, ultB)
	t.check(not s2["hero"].is_charged(), "başta şarj boş")
	s2["tm"].select_action(ultB, s2["foe"])
	t.check(s2["tm"].state == TurnManager.State.SELECTING_ACTION, "şarjsız ultimate reddedildi")

	# --- Ultimate başarı: yüksek taban + yakma DoT + şarj sıfır ---
	t.section("ultimate-başarı")
	var ultC := _mk_ult("inferno", 60, "Burn", 0.35, false, false)
	var s3 := _ult_setup(40, ultC)
	s3["hero"].charge = s3["tm"].config.charge_max
	t.check(s3["hero"].is_charged(), "şarj dolu")
	_act(s3["tm"], ultC, s3["foe"], R.PERFECT)
	var bc: DamageBreakdown = s3["tm"].last_breakdown
	t.eqf(float(bc.after_bonus), 90.0, "ultimate 60*1.5=90")
	t.eqf(float(bc.final_damage), 135.0, "zaaf ile 90*1.5=135")
	t.check(s3["foe"].pending_dot == int(round(135.0 * 0.35)), "yakma kuyruğa: 135*0.35 (got %d)" % s3["foe"].pending_dot)
	t.check(s3["hero"].charge == 0, "ultimate şarjı tüketti")

	# --- Yakma DoT: hedefin sonraki turu başında, bir kez ---
	t.section("yakma-dot")
	var hp_pre: int = s3["foe"].hp
	var dot := {"amount": 0}
	s3["tm"].dot_applied.connect(func(_c, a): dot["amount"] = a)
	s3["tm"].advance_turn()
	var expect_dot := int(round(135.0 * 0.35))
	t.check(dot["amount"] == expect_dot, "DoT sıra başında (got %d)" % dot["amount"])
	t.check(s3["foe"].hp == hp_pre - expect_dot, "yakma hasarı uygulandı")
	t.check(s3["foe"].pending_dot == 0, "DoT bir kez uygulanıp temizlendi")

	# --- Stun: hedef bir sonraki turunu atlar ---
	t.section("stun")
	var ultST := _mk_ult("pstorm", 70, "Shatter", 0.0, true, false)
	var s5 := _ult_setup(40, ultST)
	s5["hero"].charge = s5["tm"].config.charge_max
	var stunned := {"hit": false}
	s5["tm"].stun_skipped.connect(func(_c): stunned["hit"] = true)
	_act(s5["tm"], ultST, s5["foe"], R.PERFECT)
	t.check(s5["foe"].stunned, "ultimate hedefi sersemletti")
	var foe_hp5: int = s5["foe"].hp
	s5["tm"].advance_turn()
	t.check(stunned["hit"], "stun sırası atlattı")
	t.check(not s5["foe"].stunned, "stun tüketildi")
	t.check(s5["foe"].hp == foe_hp5, "atlanan turda düşman saldırmadı")

	# --- AoE ultimate: tüm düşmanlara vurur ---
	t.section("aoe-ultimate")
	var ultAoE := _mk_ult("inferno", 60, "Burn", 0.0, false, true)
	var heroA := _char("ha", 300, 50, [ultAoE])
	var e1 := _foe("e1", 300, 1, [], [_bite()])
	var e2 := _foe("e2", 300, 1, [], [_bite()])
	var tmA := TurnManager.new(_cfg())
	tmA.start_battle([heroA], [e1, e2])
	tmA.active.charge = tmA.config.charge_max
	var ta: Combatant = tmA._alive_on(Combatant.Side.ENEMY)[0]
	var oa: Combatant = tmA._alive_on(Combatant.Side.ENEMY)[1]
	_act(tmA, ultAoE, ta, R.PERFECT)
	t.check(ta.hp < 300 and oa.hp < 300, "AoE her iki düşmanı da vurdu")
	t.check(ta.hp == oa.hp, "iki düşman da eşit hasar aldı (aynı zaaf)")

	# --- Relic: Permafrost (frozen_amp) — sersem hedefe hasar artışı ---
	t.section("relic-frozen-amp")
	var rs := RelicSet.new()
	rs.add(Relic.new("permafrost", "Kalıcı Don", "", "frozen_amp", 2.0))
	var frozen := Enemy.new(); frozen.max_hp = 100
	var fc := Combatant.new(Combatant.Side.ENEMY, frozen); fc.stunned = true
	var skf := Skill.new("f", "f", "ember", 20, "Projectile", "")
	t.eqf(float(BattleDamage.compute(skf, 1.0, fc, _cfg(), rs).final_damage), 40.0, "frozen_amp: 20*2=40")
	var awake := Enemy.new(); awake.max_hp = 100
	var ac := Combatant.new(Combatant.Side.ENEMY, awake)
	t.eqf(float(BattleDamage.compute(skf, 1.0, ac, _cfg(), rs).final_damage), 20.0, "sersem değil -> amp yok")

	# --- Relic: Wildfire (burn_spread) — yakma komşulara yayılır ---
	t.section("relic-burn-spread")
	var plasma_w := _mk_ult("plasma", 40, "Burn", 0.50, false, false)
	plasma_w.requires_charge = false   # test kolaylığı: şarj gerekmesin
	var hero_w := _char("hw", 300, 50, [plasma_w])
	var w1 := _foe("w1", 200, 1, [], [Skill.new("a", "a", "", 1, "Projectile", "")])
	var w2 := _foe("w2", 200, 1, [], [Skill.new("a", "a", "", 1, "Projectile", "")])
	var rs2 := RelicSet.new()
	rs2.add(Relic.new("wildfire", "Yaban Ateşi", "", "burn_spread", 0.0))
	var tmw := TurnManager.new(_cfg(), rs2)
	tmw.start_battle([hero_w], [w1, w2])
	var tgt: Combatant = tmw._alive_on(Combatant.Side.ENEMY)[0]
	var other: Combatant = tmw._alive_on(Combatant.Side.ENEMY)[1]
	_act(tmw, plasma_w, tgt, R.MISS)   # 40 hasar, DoT 20; Wildfire -> komşuya da 20
	t.check(tgt.pending_dot == 20, "hedef DoT 20 (got %d)" % tgt.pending_dot)
	t.check(other.pending_dot == 20, "komşu da DoT 20 (Wildfire yaydı, got %d)" % other.pending_dot)

	# --- Relic: Overcharge (post_storm_amp) — Storm sonrası cast güçlenir ---
	t.section("relic-post-storm-amp")
	var storm := Skill.new("storm", "Fırtına", "storm", 10, "Area", "Shatter")
	var bolt_o := Skill.new("bolt", "Ok", "ember", 20, "Projectile", "")
	var hero_o := _char("ho", 300, 50, [storm, bolt_o])
	var e3 := _foe("e3", 500, 1, [], [Skill.new("a", "a", "", 1, "Projectile", "")])
	var rs3 := RelicSet.new()
	rs3.add(Relic.new("overcharge", "Aşırı Yük", "", "post_storm_amp", 1.5))
	var tmo := TurnManager.new(_cfg(), rs3)
	tmo.start_battle([hero_o], [e3])
	var of: Combatant = tmo._alive_on(Combatant.Side.ENEMY)[0]
	_act(tmo, storm, of, R.MISS)   # Storm cast'i -> pending_amp = 1.5
	t.check(tmo.combatants[0].pending_amp == 1.5, "Storm sonrası amp kuruldu (1.5)")
	var g2 := 0
	while tmo.state != TurnManager.State.SELECTING_ACTION and g2 < 20:
		g2 += 1
		if tmo.state == TurnManager.State.NEXT_TURN:
			tmo.advance_turn()
		else:
			break
	t.check(tmo.state == TurnManager.State.SELECTING_ACTION, "hero yeniden sırada")
	_act(tmo, bolt_o, of, R.MISS)   # bolt 20, amp 1.5 -> 30
	t.eqf(float(tmo.last_breakdown.after_bonus), 30.0, "Storm sonrası cast 20*1.5=30")
	t.check(tmo.combatants[0].pending_amp == 1.0, "amp tek kullanımda tükendi")

# Ultimate Skill kur (requires_charge + durum etkileri).
static func _mk_ult(id: String, base: int, effect: String, dot: float, stun: bool, aoe: bool) -> Skill:
	var s := Skill.new(id, id, "ember", base, "Beam", effect)
	s.requires_charge = true
	s.dot_fraction = dot
	s.applies_stun = stun
	s.aoe = aoe
	return s
