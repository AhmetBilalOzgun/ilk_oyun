extends RefCounted

# Tutorial (ilk 5 bölüm deneyerek-öğren) + ritim fail-soft testleri.
# - Tutorial eşikleri + ritim zorluk tavanları kademeli (kolaydan zora).
# - Meta.seen_hints kalıcılığı (ipucu ömür boyu bir kez).
# - RhythmMinigame FAIL-SOFT: bir nota ıskalanınca kombo BİTMEZ, kalanlar durmaz,
#   skor taban üstünde (oyunun sessiz-başarısızlık-yok ilkesi). Saf/headless.

static func run(t) -> void:
	_test_thresholds(t)
	_test_rhythm_caps(t)
	_test_hints(t)
	_test_seen_hints_persist(t)
	_test_rhythm_failsoft(t)

static func _test_thresholds(t) -> void:
	t.section("tutorial_thresholds")
	t.check(Tutorial.is_tutorial(0), "L1 (idx 0) tutorial")
	t.check(Tutorial.is_tutorial(4), "L5 (idx 4) tutorial")
	t.check(not Tutorial.is_tutorial(5), "L6 (idx 5) tutorial değil")
	t.check(not Tutorial.is_tutorial(-1), "geçersiz seviye tutorial değil")

static func _test_rhythm_caps(t) -> void:
	t.section("tutorial_rhythm_caps")
	t.check(int(Tutorial.rhythm_caps(0)["combo_len"]) == 1, "L1 tek nota (dev pencere)")
	# Kademeli: L1 hem daha yavaş hem daha kısa olmalı (kolaydan zora ramp).
	t.check(float(Tutorial.rhythm_caps(0)["speed_cap"]) < float(Tutorial.rhythm_caps(4)["speed_cap"]),
		"hız tavanı L1 < L5")
	t.check(int(Tutorial.rhythm_caps(0)["combo_len"]) <= int(Tutorial.rhythm_caps(4)["combo_len"]),
		"kombo tavanı L1 <= L5")
	t.check(float(Tutorial.rhythm_caps(9)["speed_cap"]) > 10.0, "tutorial dışı: pratikte tavan yok")

static func _test_hints(t) -> void:
	t.section("tutorial_hints")
	t.check(Tutorial.hint("rhythm") != "", "rhythm ipucu tanımlı")
	t.check(Tutorial.hint("bilinmeyen_anahtar") == "", "bilinmeyen anahtar boş döner")

static func _test_seen_hints_persist(t) -> void:
	t.section("tutorial_seen_hints")
	var m := MetaProgress.new()
	m.persist = false
	t.check(not m.has_seen_hint("rhythm"), "ipucu başta görülmemiş")
	m.mark_hint_seen("rhythm")
	t.check(m.has_seen_hint("rhythm"), "işaretlenince görülmüş sayılır")
	# to_dict/from_dict roundtrip: ipucu durumu kalıcı.
	var m2 := MetaProgress.new()
	m2.persist = false
	m2.from_dict(m.to_dict())
	t.check(m2.has_seen_hint("rhythm"), "seen_hints to_dict/from_dict ile korunur")

static func _test_rhythm_failsoft(t) -> void:
	t.section("rhythm_failsoft")
	var rm := RhythmMinigame.new()
	t.get_root().add_child(rm)
	rm.setup(3, Rect2(0, 0, 900, 560), 0.6)
	# İlk notayı ıskala (kaçan pencere) -> kombo BİTMEZ, kalan notalar düşmez.
	rm._miss_note(0, "test")
	t.check(not rm._finished, "ıska komboyu bitirmez (fail-soft)")
	t.check(not rm._notes[1]["hit"], "ıska sonraki notayı çözmez (kombo yaşar)")
	# Kalanları PERFECT işaretle: skor taban üstünde, 1/3 ıska 'broke' değil.
	rm._notes[1]["result"] = InputEvaluator.Result.PERFECT
	rm._notes[2]["result"] = InputEvaluator.Result.PERFECT
	var p: Dictionary = rm._result_payload()
	t.check(float(p["combo_score"]) > 0.0, "ıskalı komboda skor > 0 (fail-soft floor)")
	t.check(not bool(p["broke"]), "1/3 ıska broke sayılmaz (yarıdan az)")
	rm.queue_free()
