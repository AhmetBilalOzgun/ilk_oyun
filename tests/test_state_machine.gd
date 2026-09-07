extends RefCounted

# Durum makinesi testleri. EN KRİTİK: pencere timeScale'den etkilenmiyor.

static func _make(t) -> ComboStateMachine:
	var db: RuneDB = t.fixture()
	return ComboStateMachine.new(db, TimeScaleController.new(db))

static func run(t) -> void:
	t.section("timescale-merdiveni")
	var db: RuneDB = t.fixture()
	var ts := TimeScaleController.new(db)
	t.eqf(ts.compute(0, false), 1.0, "depth0 (ilk rün) tam hız")
	t.eqf(ts.compute(1, false), 0.50, "depth1 -> Rün2 hızı 0.50")
	t.eqf(ts.compute(2, false), 0.40, "depth2 -> 0.40")
	t.eqf(ts.compute(3, false), 0.30, "depth3 -> 0.30")
	t.eqf(ts.compute(9, false), 0.30, "depth9 (4+) -> son basamak 0.30")
	t.eqf(ts.compute(1, true), 0.10, "overdrive -> 0.10")

	t.section("pencere-timescale-bağımsız")  # <-- en önemli test
	var sm := _make(t)
	sm.on_finger_down()
	var spell := sm.on_finger_up("ember")   # depth1, pencere 0.60
	t.check(spell != null and sm.depth == 1, "1. rün atıldı, depth=1")
	# Dünya YAVAŞ (ts=0.50) ama pencere GERÇEK zamanla ölçülür.
	t.eqf(sm.current_time_scale, 0.50, "dünya yavaşladı (ts=0.50)")
	sm.tick(0.50)  # 0.50 gerçek sn geçti; pencere 0.60 -> 0.10 kaldı
	t.check(sm.depth == 1 and sm.window_remaining > 0.0,
		"0.50 gerçek sn sonra pencere hâlâ açık (0.10 kaldı)")
	sm.tick(0.20)  # toplam 0.70 > 0.60 -> pencere doldu
	t.check(sm.depth == 0, "pencere gerçek zamanla doldu -> depth sıfır")
	t.eqf(sm.current_time_scale, 1.0, "reset sonrası tam hız")
	# Not: pencere ölçekli olsaydı 0.50 ts ile 0.60/0.50=1.2 sn sürerdi;
	# burada 0.70 gerçek sn'de doldu -> ölçekten bağımsız. Kanıt.

	t.section("pencere-reset")
	sm = _make(t)
	sm.on_finger_down(); sm.on_finger_up("ember")
	sm.on_finger_down(); sm.on_finger_up("frost")  # depth2, pencere 0.40
	t.check(sm.depth == 2, "kombo derinleşti depth=2")
	sm.tick(0.50)  # 0.40 pencere doldu
	t.check(sm.depth == 0 and sm.current_time_scale == 1.0,
		"pencere dolunca depth ve timeScale sıfır")

	t.section("casting-pause-istismarı-yok")
	sm = _make(t)
	sm.on_finger_down()  # Casting: pencere DONAR, casting sınırı 1.2
	sm.tick(1.0)
	t.check(not sm.consume_force_commit(), "1.0 sn: henüz zorla commit yok")
	sm.tick(0.3)  # toplam 1.3 > 1.2 cap
	t.check(sm.consume_force_commit(), "casting cap dolunca zorla commit istenir")

	t.section("tanınmayan-strike")
	sm = _make(t)
	sm.on_finger_down()
	var sp := sm.on_finger_up(null)  # tanınmadı -> strike
	t.check(sp != null and sp.carrier == "Projectile" and sp.effects.is_empty(),
		"null -> strike'a düştü (etki yok)")
	t.check(sm.depth == 0, "strike STANDALONE (depth artmaz, kombo yapmaz)")
	# peş peşe strike hasarı büyütmez (sabit taban)
	var sp_again := sm.on_finger_up(null)
	t.check(sp_again.damage == sp.damage and sm.depth == 0,
		"peş peşe strike aynı hasar, depth 0 kalır")
	# geçersiz id de strike
	sm = _make(t)
	sm.on_finger_down()
	var sp2 := sm.on_finger_up("bilinmeyen_run")
	t.check(sp2.carrier == "Projectile" and sp2.effects.is_empty(), "geçersiz id -> strike")

	t.section("overdrive-tek-çıktı")
	sm = _make(t)
	sm.start_overdrive()
	t.eqf(sm.current_time_scale, 0.10, "overdrive ts=0.10")
	t.check(sm.on_finger_up("ember") == null, "overdrive'da anlık büyü yok (biriktirilir)")
	t.check(sm.on_finger_up("frost") == null, "2. rün de biriktirilir")
	sm.tick(1.5)  # süre doldu
	var od := sm.consume_overdrive_spell()
	t.check(od != null, "overdrive tek birleşik büyü üretti")
	t.check(od.effects.size() == 1 and od.effects[0] == "Steam", "aynı resolver: Burn+Freeze->Steam")
	t.eqf(float(od.damage), 64.0, "hasar: (20*1.6)=32 * overdrive 2.0 = 64")
	t.check(sm.depth == 0 and not sm.overdrive_active, "overdrive bitti -> Idle")
	t.check(sm.consume_overdrive_spell() == null, "büyü bir kez tüketilir")

	t.section("zincir-kombo-bağımsız")
	var db2: RuneDB = t.fixture()
	sm = ComboStateMachine.new(db2, TimeScaleController.new(db2))
	var chain := ChainTracker.new(db2)
	# kombo kur
	sm.on_finger_down(); sm.on_finger_up("ember")
	sm.on_finger_down(); sm.on_finger_up("frost")
	t.check(sm.depth == 2, "kombo depth=2")
	# zinciri say, sonra kır -> kombo etkilenmez
	chain.on_enemy_death(); chain.on_enemy_death(); chain.on_enemy_death()
	t.check(chain.count == 3, "zincir 3 ölüm saydı")
	chain.on_player_damaged()
	t.check(chain.count == 0, "hasar -> zincir sıfır")
	t.check(sm.depth == 2, "zincir kırılması komboyu ETKİLEMEZ")
	# komboyu kır -> zincir etkilenmez
	chain.on_enemy_death()
	sm.tick(1.0)  # pencere doldu, kombo reset
	t.check(sm.depth == 0, "kombo pencere ile sıfırlandı")
	t.check(chain.count == 1, "kombo kırılması zinciri ETKİLEMEZ")
