extends RefCounted
class_name InputEvaluator

# Aktif girdi dizisinin SAF değerlendiricisi. Ekran jestini (yakalanan Step listesi)
# beklenen diziyle karşılaştırır -> MISS / GOOD / PERFECT. Geometri/Node BİLMEZ ->
# tam test edilebilir. Sonuç enum'unu savaş motoru tüketir (bkz TurnManager.submit_input);
# motor jest ayrıntısını GÖRMEZ (bkz spec Part 19).
#
# FAIL-SOFT: yanlış girdi büyüyü İPTAL ETMEZ, sadece çarpanı düşürür.
#   PERFECT : dizi tam doğru + süre penceresi içinde.
#   GOOD    : dizi tam doğru ama yavaş, VEYA ilk adım(lar) doğru ama eksik/hatalı.
#   MISS    : ilk adım bile yanlış (yine de taban hasar verilir, çarpan 1.0).

enum Result { MISS, GOOD, PERFECT }

# expected: InputSequence. actual: Array[int] (yakalanan Step'ler).
# elapsed: diziyi tamamlama süresi (sn); <0 -> zamanlama yok say (PERFECT mümkün).
static func evaluate(expected: InputSequence, actual: Array, elapsed: float = -1.0) -> int:
	if expected == null or expected.steps.is_empty():
		return Result.PERFECT   # girdi gerekmiyor -> tam değer

	var expected_steps: Array = expected.steps
	# Baştan kaç adım ardışık eşleşiyor.
	var m := 0
	while m < expected_steps.size() and m < actual.size() and actual[m] == expected_steps[m]:
		m += 1

	if m == expected_steps.size() and actual.size() == expected_steps.size():
		# Dizi tam doğru. Zamanlama penceresi -> PERFECT, aşılmışsa GOOD.
		if elapsed < 0.0 or elapsed <= expected.window:
			return Result.PERFECT
		return Result.GOOD

	if m >= 1:
		return Result.GOOD   # ilk adım(lar) doğru -> kısmi kredi

	return Result.MISS

static func result_label(result: int) -> String:
	match result:
		Result.PERFECT: return "MÜKEMMEL!"
		Result.GOOD: return "HARİKA!"
		Result.MISS: return "ISKA!"
	return "?"
