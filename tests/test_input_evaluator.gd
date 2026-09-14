extends RefCounted

# Aktif girdi değerlendiricisi testleri (saf). PERFECT/GOOD/MISS + fail-soft +
# BattleConfig çarpan eşlemesi. Geometri yok -> tam deterministik.

const R := InputEvaluator.Result
const S := InputSequence.Step

static func run(t) -> void:
	t.section("input_evaluator")
	var seq := InputSequence.new([S.SWIPE_LEFT, S.SWIPE_RIGHT, S.TAP], 1.4)

	# Tam doğru + zamanında -> PERFECT
	t.check(InputEvaluator.evaluate(seq, [S.SWIPE_LEFT, S.SWIPE_RIGHT, S.TAP], 1.0) == R.PERFECT,
		"tam doğru + hızlı -> PERFECT")
	# Tam doğru ama yavaş -> GOOD
	t.check(InputEvaluator.evaluate(seq, [S.SWIPE_LEFT, S.SWIPE_RIGHT, S.TAP], 2.0) == R.GOOD,
		"tam doğru + yavaş -> GOOD")
	# Zamanlama verilmemiş -> PERFECT mümkün
	t.check(InputEvaluator.evaluate(seq, [S.SWIPE_LEFT, S.SWIPE_RIGHT, S.TAP]) == R.PERFECT,
		"zamanlama yok -> PERFECT")
	# İlk adımlar doğru ama eksik -> GOOD (kısmi kredi)
	t.check(InputEvaluator.evaluate(seq, [S.SWIPE_LEFT, S.SWIPE_RIGHT]) == R.GOOD,
		"eksik ama ilk adımlar doğru -> GOOD")
	# Fazladan adım (prefix doğru, uzunluk yanlış) -> GOOD
	t.check(InputEvaluator.evaluate(seq, [S.SWIPE_LEFT, S.SWIPE_RIGHT, S.TAP, S.TAP]) == R.GOOD,
		"prefix doğru + fazla adım -> GOOD")
	# İlk adım yanlış -> MISS
	t.check(InputEvaluator.evaluate(seq, [S.TAP]) == R.MISS, "ilk adım yanlış -> MISS")
	# Hiç girdi yok -> MISS
	t.check(InputEvaluator.evaluate(seq, []) == R.MISS, "boş girdi -> MISS")
	# Beklenen boş -> PERFECT (girdi gerekmiyor)
	t.check(InputEvaluator.evaluate(InputSequence.new([]), [S.TAP]) == R.PERFECT,
		"beklenen boş -> PERFECT")
	# null beklenen -> PERFECT
	t.check(InputEvaluator.evaluate(null, [S.TAP]) == R.PERFECT, "null dizi -> PERFECT")

	# BattleConfig eşlemesi (fail-soft: MISS bile taban 1.0)
	t.section("input_multiplier")
	var cfg := BattleConfig.new()
	t.eqf(cfg.input_multiplier(R.PERFECT), 1.5, "PERFECT -> 1.5")
	t.eqf(cfg.input_multiplier(R.GOOD), 1.25, "GOOD -> 1.25")
	t.eqf(cfg.input_multiplier(R.MISS), 1.0, "MISS -> 1.0 (taban)")
