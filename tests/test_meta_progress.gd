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
	_test_mastery(t)
	_test_mastery_serialize(t)

# Battle-pass: mastery XP dolunca tier'lar HAK EDİLİR ama ödül ELLE toplanır (claim_next).
static func _test_mastery(t) -> void:
	t.section("mastery_battlepass")
	var m := _meta()
	t.check(m.mastery == 0 and m.claimed_tiers == 0, "başta mastery 0")
	t.check(not m.is_archetype_unlocked("burn_build"), "başta Alev kilitli")
	m.add_mastery(39)
	t.check(m.claimable_count() == 0 and m.claimed_tiers == 0, "eşik altı (39): toplanacak yok")
	m.add_mastery(1)   # 40 -> tier0 (burn) HAK EDİLDİ ama otomatik açılmaz
	t.check(m.claimable_count() == 1, "40 mastery -> 1 tier hak edildi")
	t.check(not m.is_archetype_unlocked("burn_build"), "toplanmadan Alev hâlâ kilitli")
	var r := m.claim_next()
	t.check(r.get("value") == "burn_build" and m.is_archetype_unlocked("burn_build"), "TOPLA -> Alev açıldı")
	t.check(m.claimed_tiers == 1 and m.claimable_count() == 0, "1 tier toplandı")
	t.check(m.claim_next().is_empty(), "toplanacak yokken claim {} döner")
	m.add_mastery(200)  # 240 -> tier1(110 eşya) + tier2(200 İnfaz) hak edildi
	t.check(m.claimable_count() == 2, "240 -> 2 tier hak edildi")
	m.claim_next()      # tier1 eşya
	t.check(m.is_owned("ember_boots"), "TOPLA -> Köz Çizme (eşya)")
	m.claim_next()      # tier2 İnfaz
	t.check(m.is_archetype_unlocked("execute_build"), "TOPLA -> İnfaz")
	t.check(m.claimed_tiers == 3 and m.claimable_count() == 0, "iki tier tek tek toplandı")
	var g0 := m.gold
	m.add_mastery(80)         # 320 -> tier3 (para ödülü +200) hak edildi
	t.check(m.gold == g0, "toplanmadan altın ödülü verilmez")
	m.claim_next()
	t.check(m.gold == g0 + 200, "TOPLA -> +200 altın ödülü")

# Mastery + açılanlar to_dict/from_dict ile korunur (çifte ödül yok).
static func _test_mastery_serialize(t) -> void:
	t.section("mastery_serialize")
	var m := _meta()
	m.add_mastery(250)        # 3 tier hak edildi
	while m.claimable_count() > 0:
		m.claim_next()        # burn + ember_boots + execute topla
	var d := m.to_dict()
	var m2 := _meta()
	m2.from_dict(d)
	t.check(m2.mastery == m.mastery, "mastery serialize")
	t.check(m2.claimed_tiers == m.claimed_tiers, "claimed_tiers serialize")
	t.check(m2.is_archetype_unlocked("execute_build"), "açılan arketip serialize")
	# yeniden yüklenince eski tier tekrar ödüllenmez
	var before := m2.gold
	t.check(m2.claimable_count() == 0, "reload sonrası toplanacak yok")
	m2.claim_next()
	t.check(m2.gold == before, "reload sonrası çifte ödül yok")

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
