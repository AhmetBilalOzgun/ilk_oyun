extends RefCounted

# ChargeMeter + ChainTracker izole testleri.

static func run(t) -> void:
	var db: RuneDB = t.fixture()

	t.section("şarj-taşma-kaybı")
	var charge := ChargeMeter.new(db)
	for i in range(30):
		charge.add_hit()
	t.check(charge.is_full(), "30 isabet -> dolu")
	# doluyken kazanılan şarj KAYBOLUR
	for i in range(10):
		charge.add_hit()
	t.check(charge.hits == 30, "doluyken +10 isabet birikmez (taşma yok)")
	t.eqf(charge.ratio(), 1.0, "oran 1.0")

	t.section("şarj-tüketim")
	t.check(charge.try_consume(), "dolu halka tüketilir")
	t.check(charge.hits == 0, "tüketim sonrası sıfır")
	t.check(not charge.try_consume(), "boş halka tetiklenemez (girdi yok sayılır)")
	charge.add_hit()
	t.check(not charge.try_consume(), "yarım halka tetiklenemez")

	t.section("zincir-temel")
	var chain := ChainTracker.new(db)
	chain.on_enemy_death()
	chain.on_enemy_death()
	t.check(chain.count == 2, "2 ölüm")
	chain.on_player_damaged()
	t.check(chain.count == 0, "hasar -> sıfır (varsayılan break_on=damage)")
	# screen_pass varsayılanda zinciri kırmaz
	chain.on_enemy_death()
	chain.on_enemy_passed()
	t.check(chain.count == 1, "damage modunda ekran geçişi zinciri kırmaz")
