extends RefCounted

# Meta ilerleme testleri: upgrade maliyeti/satın alma, stat bonusları, kristal->altın
# çevrimi, seviye kilidi, kayıt serileştirme (to_dict/from_dict). persist=false ->
# dosya yazmaz. MetaProgress Node; .new() tree dışı -> _ready/load tetiklenmez.

static func _meta() -> MetaProgress:
	var m := MetaProgress.new()
	m.persist = false
	return m

static func run(t) -> void:
	_test_upgrade_costs(t)
	_test_buy_and_bonus(t)
	_test_crystal_convert(t)
	_test_level_unlock(t)
	_test_serialize(t)
	_test_rhythm_adaptive(t)

static func _test_upgrade_costs(t) -> void:
	t.section("meta_costs")
	var m := _meta()
	# Seviye 0 -> base * 1.
	t.check(m.upgrade_cost("kayra", MetaProgress.Track.HP) == MetaProgress.HP_COST_BASE,
		"CAN lvl0 maliyeti = base")
	t.check(m.upgrade_cost("kayra", MetaProgress.Track.POWER) == MetaProgress.POWER_COST_BASE,
		"HASAR lvl0 maliyeti = base")
	t.check(m.can_afford("kayra", MetaProgress.Track.HP) == false, "altın yokken alınamaz")
	m.free()

static func _test_buy_and_bonus(t) -> void:
	t.section("meta_buy")
	var m := _meta()
	m.gold = 1000
	var cost := m.upgrade_cost("kayra", MetaProgress.Track.HP)
	t.check(m.buy_upgrade("kayra", MetaProgress.Track.HP), "CAN alındı")
	t.check(m.gold == 1000 - cost, "altın düştü")
	t.check(m.track_level("kayra", MetaProgress.Track.HP) == 1, "CAN seviyesi 1")
	t.check(m.hp_bonus("kayra") == MetaProgress.HP_STEP, "CAN bonusu = 1*step")
	# Sonraki seviye daha pahalı.
	t.check(m.upgrade_cost("kayra", MetaProgress.Track.HP) == MetaProgress.HP_COST_BASE * 2,
		"CAN lvl1 maliyeti = base*2")
	# Diğer karakter etkilenmez.
	t.check(m.hp_bonus("derin") == 0, "Derin bonusu bağımsız")
	# Yetersiz altın -> reddet.
	m.gold = 0
	t.check(m.buy_upgrade("kayra", MetaProgress.Track.POWER) == false, "altınsız reddedilir")
	m.free()

static func _test_crystal_convert(t) -> void:
	t.section("meta_crystal")
	var m := _meta()
	m.crystal = 3
	m.gold = 0
	t.check(m.convert_crystal(2), "2 kristal çevrildi")
	t.check(m.crystal == 1, "kristal düştü")
	t.check(m.gold == 2 * MetaProgress.CRYSTAL_TO_GOLD, "altın = 2*oran")
	t.check(m.convert_crystal(5) == false, "yetersiz kristal reddedilir")
	t.check(m.convert_crystal(0) == false, "0 çevrim reddedilir")
	m.free()

static func _test_level_unlock(t) -> void:
	t.section("meta_levels")
	var m := _meta()
	t.check(m.is_level_unlocked(0), "seviye 0 hep açık")
	t.check(not m.is_level_unlocked(1), "seviye 1 başta kilitli")
	m.clear_level(0)
	t.check(m.is_level_unlocked(1), "seviye 0 bitince 1 açılır")
	t.check(not m.is_level_unlocked(2), "seviye 2 hâlâ kilitli")
	# Tekrar bitirmek ilerlemeyi geri almaz.
	m.clear_level(0)
	t.check(m.cleared_levels == 1, "eski seviye tekrarı ilerletmez")
	m.free()

static func _test_serialize(t) -> void:
	t.section("meta_save")
	var m := _meta()
	m.gold = 250; m.crystal = 4; m.cleared_levels = 2
	m.buy_upgrade("kayra", MetaProgress.Track.POWER)  # gold yeter (250)
	var d := m.to_dict()
	var m2 := _meta()
	m2.from_dict(d)
	t.check(m2.gold == m.gold, "gold round-trip")
	t.check(m2.crystal == 4, "crystal round-trip")
	t.check(m2.cleared_levels == 2, "cleared_levels round-trip")
	t.check(m2.track_level("kayra", MetaProgress.Track.POWER) == 1, "upgrade round-trip")
	m.free()
	m2.free()

static func _test_rhythm_adaptive(t) -> void:
	t.section("meta_rhythm_adaptive")
	# Yeni oyuncu: nötr hız çarpanı (bugünkü davranışa eşit).
	var m := _meta()
	t.check(is_equal_approx(m.rhythm_speed_scale(), MetaProgress.RHYTHM_SKILL_DEFAULT),
		"başlangıç hız çarpanı = default (nötr)")

	# İyi oynayış (hedefin üstü) => hızlanır (çarpan artar).
	for i in range(6):
		m.record_rhythm_result(1.0, false)
	t.check(m.rhythm_speed_scale() > MetaProgress.RHYTHM_SKILL_DEFAULT,
		"sürekli mükemmel => hız çarpanı artar")
	m.free()

	# Zorlanan/kombo kıran oyuncu => yavaşlar (çarpan düşer, base altına inebilir).
	var m2 := _meta()
	for i in range(6):
		m2.record_rhythm_result(0.1, true)
	t.check(m2.rhythm_speed_scale() < MetaProgress.RHYTHM_SKILL_DEFAULT,
		"sürekli kırılma => hız çarpanı düşer (kolaylaşır)")

	# Kırpma: aşırı sinyalde bile [MIN, MAX] dışına çıkmaz.
	for i in range(200):
		m2.record_rhythm_result(0.0, true)
	t.check(m2.rhythm_speed_scale() >= MetaProgress.RHYTHM_SKILL_MIN,
		"hız çarpanı MIN'e kırpılır")
	t.check(m2.rhythm_skill >= MetaProgress.RHYTHM_SKILL_MIN, "kalıcı skill MIN'e kırpılır")
	m2.free()

	# Oturum, kalıcı profilden daha hızlı tepki verir (kötü gün / el değişimi).
	# Aynı sayıda kötü cast'te oturum ağırlıklı efektif çarpan, kalıcıdan daha düşük olmalı.
	var m3 := _meta()
	m3.record_rhythm_result(0.0, true)
	t.check(m3.rhythm_speed_scale() < m3.rhythm_skill,
		"oturum hızlı tepki: efektif çarpan kalıcı profilin altında")

	# Kalıcı skill kayıtta round-trip olur; oturum kaydedilmez (RAM).
	var d := m3.to_dict()
	var m4 := _meta()
	m4.from_dict(d)
	t.check(is_equal_approx(m4.rhythm_skill, m3.rhythm_skill), "rhythm_skill round-trip")
	m3.free()
	m4.free()
