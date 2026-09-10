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
