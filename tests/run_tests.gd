extends SceneTree

# Hafif headless test runner. Çalıştır:
#   godot --headless -s res://tests/run_tests.gd
# Çekirdek sınıflar saf RefCounted → sahne gerekmez. Hata varsa exit kodu 1.

const TestResolver := preload("res://tests/test_resolver.gd")
const TestStateMachine := preload("res://tests/test_state_machine.gd")
const TestMeters := preload("res://tests/test_meters.gd")

var passed := 0
var failed := 0
var _cur := ""

# Deterministik test verisi (dosyaya bağlı değil).
static func fixture() -> RuneDB:
	return RuneDB.from_dict({
		"runes": {
			"ember":  {"carrier": "Projectile", "effect": "Burn",    "base_damage": 20},
			"frost":  {"carrier": "Cone",       "effect": "Freeze",  "base_damage": 18},
			"gale":   {"carrier": "Wave",       "effect": "Push",    "base_damage": 15},
			"storm":  {"carrier": "Area",       "effect": "Shatter", "base_damage": 24},
			"strike": {"carrier": "Projectile", "effect": null,      "base_damage": 10}
		},
		"fusions": [{"pair": ["Burn", "Freeze"], "result": "Steam"}],
		"combo_multiplier_per_rune": 1.6,
		"time_scale_ladder": {"1": 1.0, "2": 0.50, "3": 0.40, "4": 0.30, "overdrive": 0.10},
		"window_ladder_sec": {"1": 0.60, "2": 0.40, "3": 0.20},
		"combo_chain_gap_sec": 0.30,
		"casting_cap_sec": 1.2,
		"charge": {"hits_to_fill": 30},
		"overdrive": {"duration_sec": 1.5, "damage_multiplier": 2.0},
		"chain": {"break_on": "damage"},
		"weakness_wrong_effect_multiplier": 0.40
	})

func section(name: String) -> void:
	_cur = name

func check(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("  FAIL [%s] %s" % [_cur, msg])

func eqf(a: float, b: float, msg: String, eps := 0.001) -> void:
	check(abs(a - b) < eps, "%s (got %s, want %s)" % [msg, a, b])

func _initialize() -> void:
	print("== Kombo çekirdek testleri ==")
	TestResolver.run(self)
	TestStateMachine.run(self)
	TestMeters.run(self)
	print("== Sonuç: %d geçti, %d kaldı ==" % [passed, failed])
	quit(1 if failed > 0 else 0)
