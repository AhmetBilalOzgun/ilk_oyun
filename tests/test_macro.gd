extends RefCounted

# Makro sistem testleri: run PUANI (RunScore), keşif + best_score + meydan okuma
# tabloları (MetaProgress), günlük/haftalık seed + percentile stub (Challenge),
# kodeks kataloğu sayaçları (CodexData). Hepsi saf/headless.

static func _meta() -> MetaProgress:
	var m := MetaProgress.new()
	m.persist = false
	return m

static func _run_state() -> RunState:
	var cat := RunContent.catalog()
	return RunState.new(RunContent.party(), RunContent.start_forms(cat))

static func run(t) -> void:
	_test_run_score(t)
	_test_discovery(t)
	_test_score_record(t)
	_test_challenge_tables(t)
	_test_challenge_seeds(t)
	_test_percentile(t)
	_test_codex_catalog(t)

# --- RunScore -------------------------------------------------------------
static func _test_run_score(t) -> void:
	t.section("run_score")
	var rs := _run_state()
	# Boş campaign, düğüm 0, kayıp -> yalnız (node_index+1)*NODE.
	t.check(RunScore.compute(rs, false) == RunScore.NODE, "boş run: 1 düğüm puanı")
	# Zafer bonusu.
	t.check(RunScore.compute(rs, true) == RunScore.NODE + RunScore.WIN, "zafer bonusu eklenir")
	# Bileşenler toplanır.
	rs.node_index = 4
	rs.gold = 30
	rs.relics = [Relic.new("r1"), Relic.new("r2")]
	rs.elites_won = 1
	rs.bosses_won = 1
	rs.loadout("ember").add_archetype(RunContent.ember_archetypes()[0])
	var want := 5 * RunScore.NODE + RunScore.WIN + 30 * RunScore.GOLD \
		+ 2 * RunScore.RELIC + 1 * RunScore.ARCHETYPE \
		+ 1 * RunScore.ELITE + 1 * RunScore.BOSS
	t.check(RunScore.compute(rs, true) == want, "campaign bileşen toplamı")
	# Endless: derinlik puanı, WIN yok.
	var es := _run_state()
	es.endless = true
	es.depth = 7
	t.check(RunScore.compute(es, false) == 7 * RunScore.DEPTH, "endless: kat başına DEPTH, WIN yok")

# --- Keşif (kodeks) -------------------------------------------------------
static func _test_discovery(t) -> void:
	t.section("discovery")
	var m := _meta()
	t.check(not m.is_discovered("form:ember"), "başta keşfedilmemiş")
	t.check(m.discover("form:ember"), "ilk keşif true")
	t.check(not m.discover("form:ember"), "tekrar keşif false")
	t.check(m.is_discovered("form:ember"), "keşif kalıcı işaretli")
	t.check(not m.discover(""), "boş anahtar keşif değil")
	# Serileştirme keşifleri taşır.
	var m2 := _meta()
	m2.from_dict(m.to_dict())
	t.check(m2.is_discovered("form:ember"), "keşif to_dict/from_dict ile taşınır")

# --- best_score ----------------------------------------------------------
static func _test_score_record(t) -> void:
	t.section("score_record")
	var m := _meta()
	t.check(m.best_score == 0, "başta best 0")
	t.check(m.record_score(120), "ilk skor rekor")
	t.check(m.best_score == 120, "best güncellendi")
	t.check(not m.record_score(100), "düşük skor rekor değil")
	t.check(m.record_score(200), "yüksek skor yeni rekor")
	t.check(m.best_score == 200, "best 200")

# --- Meydan okuma tabloları ----------------------------------------------
static func _test_challenge_tables(t) -> void:
	t.section("challenge_tables")
	var m := _meta()
	t.check(m.challenge_best("daily", 20260916) == 0, "başta günlük skor yok")
	t.check(m.record_challenge_score("daily", 20260916, 300), "ilk günlük skor")
	t.check(m.challenge_best("daily", 20260916) == 300, "günlük skor kaydedildi")
	t.check(not m.record_challenge_score("daily", 20260916, 250), "düşük günlük rekor değil")
	# Ayrı seed ayrı tablo; günlük ile haftalık karışmaz.
	t.check(m.challenge_best("daily", 20260917) == 0, "başka gün ayrı skor")
	t.check(m.record_challenge_score("weekly", 202637, 500), "haftalık ayrı tablo")
	t.check(m.challenge_best("daily", 202637) == 0, "haftalık seed günlükte yok")
	var m2 := _meta()
	m2.from_dict(m.to_dict())
	t.check(m2.challenge_best("daily", 20260916) == 300, "meydan tabloları serileşir")

# --- Challenge seed deterministik ----------------------------------------
static func _test_challenge_seeds(t) -> void:
	t.section("challenge_seeds")
	var d := {"year": 2026, "month": 9, "day": 16}
	t.check(Challenge.daily_seed(d) == 20260916, "günlük seed YYYYMMDD")
	# Aynı gün -> aynı seed; ertesi gün -> farklı.
	t.check(Challenge.daily_seed(d) == Challenge.daily_seed(d), "günlük seed deterministik")
	var d2 := {"year": 2026, "month": 9, "day": 17}
	t.check(Challenge.daily_seed(d) != Challenge.daily_seed(d2), "farklı gün farklı seed")
	# Aynı haftadaki iki gün -> aynı haftalık seed (16 ve 17 Eylül aynı hafta dilimi).
	t.check(Challenge.weekly_seed(d) == Challenge.weekly_seed(d2), "aynı hafta aynı seed")
	var far := {"year": 2026, "month": 12, "day": 31}
	t.check(Challenge.weekly_seed(d) != Challenge.weekly_seed(far), "uzak hafta farklı seed")

# --- Percentile stub ------------------------------------------------------
static func _test_percentile(t) -> void:
	t.section("percentile")
	# Monoton artan + [1,99] sınırlı.
	t.check(Challenge.percentile(0) >= 1, "alt sınır >=1")
	t.check(Challenge.percentile(100000) <= 99, "üst sınır <=99")
	t.check(Challenge.percentile(1000) > Challenge.percentile(100), "yüksek skor daha yüksek percentile")
	# Referans skor ~orta.
	var mid := Challenge.percentile(int(Challenge.REF))
	t.check(mid >= 45 and mid <= 54, "REF skor ~%50")

# --- CodexData katalog ----------------------------------------------------
static func _test_codex_catalog(t) -> void:
	t.section("codex_catalog")
	var cats := CodexData.categories()
	t.check(cats.size() == 4, "4 kategori (form/arketip/relik/düşman)")
	t.check(CodexData.total_count() > 0, "katalog boş değil")
	# discovered_count yalnız katalogdaki anahtarları sayar (eski/geçersiz sayılmaz).
	var disc := ["form:ember", "gecersiz:anahtar"]
	t.check(CodexData.discovered_count(disc) == 1, "yalnız katalog anahtarı sayılır")
	# Toplam = kategori entry toplamı.
	var sum := 0
	for c in cats:
		sum += (c["entries"] as Array).size()
	t.check(CodexData.total_count() == sum, "total_count = kategori toplamı")
	# Plazma arketipleri katalogda (Faz-2 kanıtı).
	var found_plasma := false
	for e in CodexData.archetypes():
		if String(e["key"]).begins_with("arch:plasma:"):
			found_plasma = true
	t.check(found_plasma, "plazma arketipleri kodekste")
