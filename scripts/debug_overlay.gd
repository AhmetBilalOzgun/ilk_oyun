extends CanvasLayer
class_name DebugOverlay

# Kombo prototip debug overlay'i. Her kare: timeScale, kombo derinliği, kalan
# pencere, şarj %, zincir, son büyünün taşıyıcı+etki+hasar dökümü, state.
# F1 ile aç/kapa. Koddan kurulur (main.gd _make_bar deseni gibi, tscn'e dokunmaz).

var _label: Label

const _STATE_NAMES := {0: "Idle", 1: "Casting", 2: "Window"}

func _ready() -> void:
	layer = 100
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.55)
	panel.position = Vector2(16, 16)
	panel.size = Vector2(520, 300)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_label = Label.new()
	_label.position = Vector2(28, 26)
	_label.add_theme_font_size_override("font_size", 26)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		visible = not visible

# main._process'ten çağrılır.
func update_view(sm: ComboStateMachine, charge: ChargeMeter, chain: ChainTracker) -> void:
	if _label == null:
		return
	var spell_txt := "-"
	if sm.last_spell != null:
		spell_txt = sm.last_spell.describe()
		if not sm.last_spell.fusion_notes.is_empty():
			spell_txt += "  [" + ", ".join(sm.last_spell.fusion_notes) + "]"
	var od := "  <OVERDRIVE %.2fs>" % sm.overdrive_remaining if sm.overdrive_active else ""
	_label.text = "\n".join([
		"timeScale : %.2f%s" % [sm.current_time_scale, od],
		"state     : %s" % _STATE_NAMES.get(sm.state, "?"),
		"kombo     : derinlik %d" % sm.depth,
		"pencere   : %.2f sn" % max(0.0, sm.window_remaining),
		"şarj      : %d%%  %s" % [int(round(charge.ratio() * 100.0)), "DOLU" if charge.is_full() else ""],
		"zincir    : %d" % chain.count,
		"son büyü  : %s" % spell_txt,
		"",
		"(F1: overlay aç/kapa)",
	])
