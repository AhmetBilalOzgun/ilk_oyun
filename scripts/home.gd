extends Control

# Ana ekran (home). Para çubuğu (Altın/Kristal) + OYNA (seviye seçimi) +
# KARAKTERLER + KRİSTAL->ALTIN çevir + ÇIKIŞ. Meta autoload'u paylaşır.
# KRİSTAL AL = IAP stub (gerçek-para yerine test amaçlı +5 kristal).

const LEVEL_SELECT := "res://scenes/level_select.tscn"
const CHARACTERS := "res://scenes/characters.tscn"

var _currency: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.1, 0.15, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_currency = _label("", 44, Vector2(60, 60))
	add_child(_currency)
	_refresh_currency()

	var title := _label("RÜN BÜYÜCÜSÜ", 72, Vector2(60, 240))
	title.add_theme_color_override("font_color", Color(0.99, 0.85, 0.4))
	add_child(title)

	var box := VBoxContainer.new()
	box.position = Vector2(180, 560)
	box.add_theme_constant_override("separation", 40)
	add_child(box)

	box.add_child(_button("OYNA", _on_play))
	box.add_child(_button("KARAKTERLER", _on_characters))
	box.add_child(_button("KRİSTAL → ALTIN", _on_convert))
	box.add_child(_button("KRİSTAL AL (test +5)", _on_buy_crystal))
	box.add_child(_button("ÇIKIŞ", func(): get_tree().quit()))

func _refresh_currency() -> void:
	_currency.text = "💰 Altın: %d      💎 Kristal: %d" % [Meta.gold, Meta.crystal]

func _on_play() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT)

func _on_characters() -> void:
	get_tree().change_scene_to_file(CHARACTERS)

func _on_convert() -> void:
	if Meta.convert_crystal(1):
		_refresh_currency()

func _on_buy_crystal() -> void:
	Meta.add_crystal(5)   # IAP stub
	_refresh_currency()

# --- UI yardımcıları ---

func _label(text: String, fsize: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", fsize)
	return l

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(720, 140)
	b.add_theme_font_size_override("font_size", 48)
	b.pressed.connect(cb)
	return b
