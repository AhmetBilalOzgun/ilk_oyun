extends SceneTree

# Hafif headless test runner. Çalıştır:
#   godot --headless -s res://tests/run_tests.gd
# Çekirdek sınıflar saf RefCounted → sahne gerekmez. Hata varsa exit kodu 1.
# Eski gerçek-zamanlı kombo motoru silindiğinde ilgili suite'ler (resolver /
# state_machine / meters) kaldırıldı. Kalan: turn-based savaş.

const TestTurnManager := preload("res://tests/test_turn_manager.gd")
const TestRunManager := preload("res://tests/test_run_manager.gd")
const TestRunMap := preload("res://tests/test_run_map.gd")
const TestMetaProgress := preload("res://tests/test_meta_progress.gd")
const TestInputEvaluator := preload("res://tests/test_input_evaluator.gd")
const TestMageForm := preload("res://tests/test_mage_form.gd")
const TestEquipment := preload("res://tests/test_equipment.gd")
const TestMacro := preload("res://tests/test_macro.gd")
const TestTutorial := preload("res://tests/test_tutorial.gd")

const TestVisualRevision := preload("res://tests/test_visual_revision.gd")

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
	print("== Aktif girdi testleri ==")
	TestInputEvaluator.run(self)
	print("== MageForm testleri ==")
	TestMageForm.run(self)
	print("== Turn-based savaş testleri ==")
	TestTurnManager.run(self)
	print("== Run omurgası testleri ==")
	TestRunManager.run(self)
	print("== Run harita testleri ==")
	TestRunMap.run(self)
	print("== Meta ilerleme testleri ==")
	TestMetaProgress.run(self)
	print("== Ekipman testleri ==")
	TestEquipment.run(self)
	print("== Makro sistem testleri (puan/keşif/meydan/kodeks) ==")
	TestMacro.run(self)
	print("== Tutorial + ritim fail-soft testleri ==")
	TestTutorial.run(self)
	TestVisualRevision.run(self)
	print("== Sonuç: %d geçti, %d kaldı ==" % [passed, failed])
	quit(1 if failed > 0 else 0)
