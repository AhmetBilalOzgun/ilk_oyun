extends RefCounted
class_name RelicSet

# Bir run'da aktif olan kural taşıyıcılarının kümesi. Saf/headless. Savaş motoru
# hook noktalarında bunu sorgular (has/amount). Aynı hook birden çok taşıyıcıda ise
# amount'lar çarpılır. Relic VEYA Equipment kabul eder (duck-typed: .hook + .amount).

var relics: Array = []   # Relic ya da Equipment (ikisi de hook+amount taşır)

func add(relic) -> void:
	relics.append(relic)

func has(hook: String) -> bool:
	for r in relics:
		if r.hook == hook:
			return true
	return false

# Verilen hook için birleşik çarpan. Hiç yoksa default (nötr, tipik 1.0) döner;
# birden çok relic aynı hook'u taşırsa amount'lar çarpılır.
func amount(hook: String, default: float = 1.0) -> float:
	var out := default
	var found := false
	for r in relics:
		if r.hook == hook:
			out = out * r.amount if found else r.amount
			found = true
	return out
