extends RefCounted

# Turn-based savaş testleri: sıra hesaplama, QTE bonus, fail-soft (kritik),
# zaaf/direnç çarpanları (asla sıfır). Çekirdek saf RefCounted -> sahne gerekmez.

static func _cfg() -> BattleConfig:
	var c := BattleConfig.new()
	c.weakness_multiplier = 1.5
	c.resist_multiplier = 0.5
	return c

# Tek parti + tek düşman, oyuncu sırası garanti (speed yüksek) kurulumu.
static func _duel(player_speed: int, enemy_speed: int) -> Array:
	var hero := Character.new()
	hero.id = "hero"
	hero.display_name = "Kahraman"
	hero.max_hp = 100
	hero.speed = player_speed
	hero.skills = [Skill.new("bolt", "Ok", "ember", 20, 2.0, 1.5, "Projectile", "Burn")]

	var foe := Enemy.new()
	foe.id = "foe"
	foe.display_name = "Yaratık"
	foe.max_hp = 200
	foe.speed = enemy_speed
	foe.weakness_effects = ["Burn"]   # ember -> Burn -> zaaf
	foe.resist_effects = []
	foe.skills = [Skill.new("bite", "Isır", "", 7, 0.0, 1.0, "Projectile", "")]
	return [[hero], [foe]]

# Birleşim testleri için: hero (bolt + plasma + tempest), tek foe (Burn zaafı),
# recognizer YOK -> submit_qte doğrudan çağrılır (adım rünü kontrol edilebilsin).
# hero hızlı (önce), foe yavaş + yüksek HP (birden çok tur yaşar).
static func _combo_setup(charge_max: int, foe_hp: int) -> Dictionary:
	var hero := Character.new()
	hero.id = "h"; hero.display_name = "Kahraman"; hero.max_hp = 300; hero.speed = 50
	var bolt := Skill.new("bolt", "Ok", "ember", 20, 2.0, 1.5, "Projectile", "Burn")
	var plasma := Skill.new("plasma", "Plazma", "", 44, 2.0, 2.5, "Beam", "Burn")
	plasma.requires_charge = true
	plasma.rune_sequence = ["ember", "storm"]
	plasma.dot_fraction = 0.40
	var tempest := Skill.new("tempest", "Fırtına", "", 33, 2.0, 2.5, "Storm", "Freeze")
	tempest.requires_charge = true
	tempest.rune_sequence = ["frost", "gale"]
	tempest.applies_stun = true
	hero.skills = [bolt, plasma, tempest]

	var foe := Enemy.new()
	foe.id = "f"; foe.display_name = "Yaratık"; foe.max_hp = foe_hp; foe.speed = 1
	foe.weakness_effects = ["Burn"]
	foe.skills = [Skill.new("bite", "Isır", "", 7, 0.0, 1.0, "Projectile", "")]

	var cfg := _cfg()
	cfg.charge_max = charge_max
	var tm := TurnManager.new(cfg)
	tm.start_battle([hero], [foe])
	return {
		"tm": tm, "hero": tm.active, "foe": tm._alive_on(Combatant.Side.ENEMY)[0],
		"bolt": bolt, "plasma": plasma, "tempest": tempest,
	}

static func run(t) -> void:
	# --- Sıra hesaplama: speed azalan, stabil ---
	t.section("sıra-hesaplama")
	var party := TestBattleData.party()      # Kayra 14, Derin 18
	var enemies := TestBattleData.enemies()  # Golem 8, Wraith 20
	var tm := TurnManager.new(_cfg())
	tm.start_battle(party, enemies)
	var speeds: Array = []
	for c in tm.order:
		speeds.append(c.speed())
	t.check(speeds == [20, 18, 14, 8],
		"sıra speed'e göre azalan (got %s)" % [speeds])
	t.check(tm.order[0].display_name() == "Alev Hayaleti",
		"en hızlı (Wraith 20) ilk sırada")

	# --- QTE başarısı doğru çarpanı uygular ---
	t.section("qte-başarı-çarpanı")
	var d := _duel(50, 1)  # oyuncu önce
	var tm2 := TurnManager.new(_cfg(), FakeRecognizer.new("ember"))
	tm2.start_battle(d[0], d[1])
	t.check(tm2.state == TurnManager.State.SELECTING_ACTION, "oyuncu sırası açıldı")
	var skill: Skill = tm2.active.skills()[0]
	var foe: Combatant = tm2._alive_on(Combatant.Side.ENEMY)[0]
	tm2.select_action(skill, foe)
	t.check(tm2.state == TurnManager.State.QTE, "beceri seçilince QTE")
	tm2.submit_drawing([])  # FakeRecognizer "ember" -> doğru rün -> başarı
	var b: DamageBreakdown = tm2.last_breakdown
	# base 20 * bonus 1.5 = 30, sonra zaaf (Burn) *1.5 = 45
	t.check(b.qte_success, "QTE başarılı işaretlendi")
	t.eqf(float(b.after_bonus), 30.0, "bonus sonrası 20*1.5=30")
	t.eqf(float(b.weakness_multiplier), 1.5, "zaaf (Burn) çarpanı uygulandı")
	t.eqf(float(b.final_damage), 45.0, "nihai 30*1.5=45")

	# --- QTE başarısızlığı taban hasarı İPTAL ETMEZ (fail-soft, kritik) ---
	t.section("qte-fail-soft")
	# yanlış rün
	var d2 := _duel(50, 1)
	var tm3 := TurnManager.new(_cfg(), FakeRecognizer.new("frost"))  # beklenen ember
	tm3.start_battle(d2[0], d2[1])
	var sk3: Skill = tm3.active.skills()[0]
	var foe3: Combatant = tm3._alive_on(Combatant.Side.ENEMY)[0]
	var hp_before: int = foe3.hp
	tm3.select_action(sk3, foe3)
	tm3.submit_drawing([])
	var b3: DamageBreakdown = tm3.last_breakdown
	t.check(not b3.qte_success, "yanlış rün -> QTE başarısız")
	t.eqf(float(b3.after_bonus), 20.0, "başarısızlıkta bonus yok: taban 20")
	# taban 20 * zaaf 1.5 = 30 (zaaf hâlâ uygulanır, bonus ayrı)
	t.eqf(float(b3.final_damage), 30.0, "taban hâlâ uygulandı (zaafla 30)")
	t.check(b3.final_damage > 0, "saldırı iptal edilmedi")
	t.check(foe3.hp == hp_before - 30, "hedef gerçekten hasar aldı")

	# süre dolması da fail-soft: taban uygulanır
	var d4 := _duel(50, 1)
	var tm4 := TurnManager.new(_cfg(), FakeRecognizer.new("ember"))
	tm4.start_battle(d4[0], d4[1])
	var sk4: Skill = tm4.active.skills()[0]
	var foe4: Combatant = tm4._alive_on(Combatant.Side.ENEMY)[0]
	tm4.select_action(sk4, foe4)
	tm4.tick(99.0)  # süre aşıldı
	t.check(tm4.state == TurnManager.State.NEXT_TURN, "süre dolunca çözüldü")
	t.check(not tm4.last_breakdown.qte_success, "timeout -> başarısız")
	t.eqf(float(tm4.last_breakdown.final_damage), 30.0, "timeout'ta taban uygulandı")

	# --- Zaaf / direnç çarpanları, hiçbir zaman sıfır ---
	t.section("zaaf-direnç")
	var cfg := _cfg()
	# zaaf
	var weak_enemy := Enemy.new()
	weak_enemy.max_hp = 100
	weak_enemy.weakness_effects = ["Burn"]
	var wc := Combatant.new(Combatant.Side.ENEMY, weak_enemy)
	var sk := Skill.new("f", "f", "ember", 20, 2.0, 1.5, "Projectile", "Burn")
	var bw := BattleDamage.compute(sk, false, wc, cfg)
	t.eqf(float(bw.final_damage), 30.0, "zaaf: 20*1.5=30")
	# direnç
	var res_enemy := Enemy.new()
	res_enemy.max_hp = 100
	res_enemy.resist_effects = ["Burn"]
	var rc := Combatant.new(Combatant.Side.ENEMY, res_enemy)
	var br := BattleDamage.compute(sk, false, rc, cfg)
	t.eqf(float(br.final_damage), 10.0, "direnç: 20*0.5=10")
	t.check(br.final_damage > 0, "direnç hasarı sıfırlamaz")
	# aşırı direnç + küçük taban -> yine min 1, asla 0
	var tiny := Skill.new("t", "t", "gale", 1, 2.0, 1.5, "Wave", "Push")
	var res2 := Enemy.new()
	res2.max_hp = 100
	res2.resist_effects = ["Push"]
	var rc2 := Combatant.new(Combatant.Side.ENEMY, res2)
	var br2 := BattleDamage.compute(tiny, false, rc2, cfg)
	t.check(br2.final_damage >= 1, "min 1 hasar tabanı (got %d)" % br2.final_damage)

	# --- Tam savaş: bir taraf elenince battle_ended ---
	t.section("savaş-sonu")
	var d5 := _duel(50, 1)
	var tm5 := TurnManager.new(_cfg(), FakeRecognizer.new("ember"))
	var ended := {"winner": -1}
	tm5.battle_ended.connect(func(w): ended["winner"] = w)
	tm5.start_battle(d5[0], d5[1])
	# foe 200 HP, her vuruş 45 -> birkaç tur. Oyuncu vur, düşman vur, tekrar.
	var guard := 0
	while tm5.state != TurnManager.State.BATTLE_OVER and guard < 100:
		guard += 1
		if tm5.state == TurnManager.State.SELECTING_ACTION:
			var a: Combatant = tm5.active
			var target: Combatant = tm5._alive_on(Combatant.Side.ENEMY)[0]
			tm5.select_action(a.skills()[0], target)
			tm5.submit_drawing([])
		elif tm5.state == TurnManager.State.NEXT_TURN:
			tm5.advance_turn()
		else:
			break
	t.check(tm5.state == TurnManager.State.BATTLE_OVER, "savaş bitti")
	t.check(ended["winner"] == Combatant.Side.PARTY, "parti kazandı (düşman elendi)")

	# --- Şarj barı: verilen + alınan hasar kadar dolar ---
	t.section("şarj-dolumu")
	var s := _combo_setup(1000, 500)   # eşik yüksek -> kolay dolmasın
	var tmc: TurnManager = s["tm"]
	var heroc: Combatant = s["hero"]
	var foec: Combatant = s["foe"]
	tmc.select_action(s["bolt"], foec)
	tmc.submit_qte("ember")   # doğru -> başarı; 20*1.5=30, foe Burn zaafı *1.5=45
	t.check(heroc.charge == 45, "vuran verilen hasar kadar şarj (got %d)" % heroc.charge)
	t.check(foec.charge == 45, "yiyen alınan hasar kadar şarj (got %d)" % foec.charge)

	# --- Birleşim kilidi: şarj dolu değilse seçilemez ---
	t.section("birleşim-kilit")
	var s2 := _combo_setup(40, 500)
	var tm_l: TurnManager = s2["tm"]
	var foe_l: Combatant = s2["foe"]
	t.check(not s2["hero"].is_charged(), "başta şarj boş")
	tm_l.select_action(s2["plasma"], foe_l)
	t.check(tm_l.state == TurnManager.State.SELECTING_ACTION,
		"şarjsız birleşim reddedildi (QTE'ye geçmedi)")

	# --- Birleşim başarı: dizi tam çizilince BÜYÜK buff + yakma DoT + şarj sıfır ---
	t.section("birleşim-başarı")
	var s3 := _combo_setup(40, 500)
	var tm3c: TurnManager = s3["tm"]
	var heroS: Combatant = s3["hero"]
	var foeS: Combatant = s3["foe"]
	heroS.charge = tm3c.config.charge_max   # doğrudan doldur (dolum ayrı test edildi)
	t.check(heroS.is_charged(), "şarj dolu")
	tm3c.select_action(s3["plasma"], foeS)
	t.check(tm3c.state == TurnManager.State.QTE, "birleşim seçildi -> QTE")
	tm3c.submit_qte("ember")
	t.check(tm3c.state == TurnManager.State.QTE, "1. rün doğru -> QTE devam")
	t.check(tm3c.qte_progress == 1, "ilerleme 1")
	tm3c.submit_qte("storm")
	var bc: DamageBreakdown = tm3c.last_breakdown
	t.check(bc.qte_success, "dizi tam -> başarı")
	t.eqf(float(bc.after_bonus), 110.0, "büyük buff: 44*2.5=110")
	t.eqf(float(bc.final_damage), 165.0, "zaaf ile 110*1.5=165")
	t.check(foeS.pending_dot == 66, "yakma kuyruğa: 165*0.40=66 (got %d)" % foeS.pending_dot)
	t.check(heroS.charge == 0, "birleşim şarjı tüketti")

	# --- Birleşim fail-soft: yanlış rün -> taban (buff yok) ama şarj yine gider ---
	t.section("birleşim-fail-soft")
	var s4 := _combo_setup(40, 500)
	var tm4c: TurnManager = s4["tm"]
	var heroF: Combatant = s4["hero"]
	var foeF: Combatant = s4["foe"]
	heroF.charge = tm4c.config.charge_max
	tm4c.select_action(s4["plasma"], foeF)
	tm4c.submit_qte("ember")
	tm4c.submit_qte("frost")   # yanlış (storm bekleniyordu) -> dizi başarısız
	var b4: DamageBreakdown = tm4c.last_breakdown
	t.check(not b4.qte_success, "yanlış rün -> başarısız")
	t.eqf(float(b4.after_bonus), 44.0, "buff yok: taban 44")
	t.eqf(float(b4.final_damage), 66.0, "taban hâlâ uygulandı (zaafla 44*1.5=66)")
	t.check(heroF.charge == 0, "başarısız birleşim de şarjı tüketti")

	# --- Yakma DoT: hedefin sonraki turu başında uygulanır, bir kez ---
	t.section("yakma-dot")
	var hp_pre_dot: int = foeS.hp        # birleşim-başarı'daki foe (pending_dot 66)
	var dot := {"amount": 0}
	tm3c.dot_applied.connect(func(_c, a): dot["amount"] = a)
	tm3c.advance_turn()                  # foe sırası -> DoT uygulanır
	t.check(dot["amount"] == 66, "DoT sıra başında tetiklendi (got %d)" % dot["amount"])
	t.check(foeS.hp == hp_pre_dot - 66, "yakma hasarı uygulandı")
	t.check(foeS.pending_dot == 0, "DoT bir kez uygulanıp temizlendi")

	# --- Stun: hedef bir sonraki turunu atlar ---
	t.section("stun")
	var s5 := _combo_setup(40, 500)
	var tm5c: TurnManager = s5["tm"]
	var hero5: Combatant = s5["hero"]
	var foe5: Combatant = s5["foe"]
	hero5.charge = tm5c.config.charge_max
	var stunned := {"hit": false}
	tm5c.stun_skipped.connect(func(_c): stunned["hit"] = true)
	tm5c.select_action(s5["tempest"], foe5)
	tm5c.submit_qte("frost")
	tm5c.submit_qte("gale")
	t.check(foe5.stunned, "tempest hedefi sersemletti")
	var foe_hp5: int = foe5.hp
	tm5c.advance_turn()                  # foe sırası -> stun -> atla
	t.check(stunned["hit"], "stun sırası atlattı")
	t.check(not foe5.stunned, "stun tüketildi")
	t.check(foe5.hp == foe_hp5, "atlanan turda düşman saldırmadı (HP değişmedi)")
