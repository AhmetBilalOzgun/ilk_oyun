extends RefCounted
class_name BattleConfig

# Savaş tuning'i. Saf/headless. TurnManager'a verilir; verilmezse varsayılanlar.
# charge_max: birleşim (ultimate) becerisini açan şarj barı eşiği. Hasar
# verildikçe/alındıkça miktar kadar dolar (bkz Combatant.gain_charge).

var weakness_multiplier: float = 1.5    # zaaf etkisiyle vurunca ekstra
var resist_multiplier: float = 0.5      # direnç etkisiyle vurunca azaltma (asla 0)
var charge_max: int = 100               # ultimate becerisi bu eşikte açılır

# Aktif girdi (tap/swipe) sonucu -> hasar çarpanı. FAIL-SOFT: ıska bile taban verir.
var miss_multiplier: float = 1.0        # MISS: taban hasar (büyü iptal olmaz)
var good_multiplier: float = 1.25       # GOOD: kısmi/yavaş doğru dizi
var perfect_multiplier: float = 1.5     # PERFECT: tam doğru + zamanında

# InputEvaluator.Result -> çarpan. TurnManager.submit_input bunu kullanır.
func input_multiplier(result: int) -> float:
	match result:
		InputEvaluator.Result.PERFECT: return perfect_multiplier
		InputEvaluator.Result.GOOD: return good_multiplier
	return miss_multiplier
