extends SceneTree

# Hafif headless test runner. Çalıştır:
#   godot --headless -s res://tests/run_tests.gd
# Çekirdek sınıflar saf RefCounted → sahne gerekmez. Hata varsa exit kodu 1.
# Eski gerçek-zamanlı kombo motoru silindiğinde ilgili suite'ler (resolver /
# state_machine / meters) kaldırıldı. Kalan: turn-based savaş.

const TestTurnManager := preload("res://tests/test_turn_manager.gd")

var passed := 0
var failed := 0
var _cur := ""

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
	print("== Turn-based savaş testleri ==")
	TestTurnManager.run(self)
	print("== Sonuç: %d geçti, %d kaldı ==" % [passed, failed])
	quit(1 if failed > 0 else 0)
