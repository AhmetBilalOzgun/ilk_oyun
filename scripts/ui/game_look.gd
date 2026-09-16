extends RefCounted
class_name GameLook

const INK := Color("354d58")
const CREAM := Color("fff4d9")
const TEAL := Color("65b7a0")
const CORAL := Color("e99770")
const FONT = preload("res://assets/fonts/PixelifySans-Bold.ttf")
const WORLDS := ["meadow", "orchard", "coast", "autumn", "snow"]
const GROUND_RATIOS := [0.675, 0.665, 0.65, 0.675, 0.62]
const WORLD_NAMES := ["Papatya Köprüsü", "Çiçek Bahçesi", "Deniz İskelesi", "Altın Yaprak Korusu", "Pamuk Kar Vadisi"]

static func world_index(level: int) -> int:
	return clampi(floori(level / 4.0), 0, 4)

static func backdrop(index: int) -> Texture2D:
	return load("res://assets/worlds/%s.png" % WORLDS[posmod(index, 5)])

static func panel(color := CREAM, border := INK) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(4)
	s.set_corner_radius_all(12)
	s.shadow_color = Color(0.18, 0.29, 0.32, 0.18)
	s.shadow_size = 0
	s.shadow_offset = Vector2(0, 6)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s

static func button(b: Button, accent := TEAL, font_size := 34) -> void:
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", panel(CREAM, accent.darkened(0.25)))
	b.add_theme_stylebox_override("hover", panel(Color("fffaf0"), accent))
	b.add_theme_stylebox_override("pressed", panel(accent.lightened(0.5), accent.darkened(0.3)))
	b.add_theme_stylebox_override("disabled", panel(Color("e3e5d8"), Color("a4b5ac")))
	b.add_theme_stylebox_override("focus", panel(Color(0, 0, 0, 0), Color("dc965d")))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, INK)
	b.add_theme_color_override("font_disabled_color", Color("75867f"))
	b.add_theme_constant_override("outline_size", 0)

static func label(text: String, size := 32) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func background(parent: Control, index := 0) -> void:
	var bg := TextureRect.new()
	bg.texture = backdrop(index)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)

static func card(parent: Node, rect: Rect2) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", panel())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

static func frames(key: String) -> SpriteFrames:
	if key == "fire":
		return load("res://assets/wizard/wizard_fire_frames.tres")
	return load("res://assets/wizard/forms/%s_frames.tres" % key)

static func form_key(lo: RunLoadout) -> String:
	var plasma := lo.current_form != null and lo.current_form.id == "plasma"
	var base := "plasma" if plasma else "fire"
	if lo.archetypes.is_empty():
		return base
	match lo.archetypes[0].id:
		"execute_build": return base + "_crit"
		"explosion_build": return base + "_explosive"
		"burn_build": return "plasma_blind" if plasma else "fire_burn"
	return base
