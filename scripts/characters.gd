extends Control

# Karakterler ekranı. Üstte para çubuğu + karakter seçim butonları; altta seçili
# karakterin özellikleri + 2 upgrade track'i (CAN / HASAR, altınla). Upgrade alınca
# Meta'ya yazılır, panel + para çubuğu yenilenir. Geri -> home.

const HOME := "res://scenes/home.tscn"

var _chars: Array = []          # Array[Character] (RunContent.party)
var _by_id: Dictionary = {}     # id -> Character
var _selected_id: String = ""

var _currency: Label
var _detail: VBoxContainer

func _ready() -> void:
	_chars = RunContent.party()
	for c in _chars:
		_by_id[c.id] = c

	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.1, 0.15, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_currency = Label.new()
	_currency.position = Vector2(60, 50)
	_currency.add_theme_font_size_override("font_size", 40)
	add_child(_currency)

	# Karakter seçim butonları (yatay).
	var row := HBoxContainer.new()
	row.position = Vector2(60, 150)
	row.add_theme_constant_override("separation", 30)
	add_child(row)
	for c in _chars:
		var b := Button.new()
		b.text = c.display_name
		b.custom_minimum_size = Vector2(300, 120)
		b.add_theme_font_size_override("font_size", 44)
		b.pressed.connect(_on_select.bind(c.id))
		row.add_child(b)

	# Detay paneli.
	_detail = VBoxContainer.new()
	_detail.position = Vector2(60, 340)
	_detail.add_theme_constant_override("separation", 24)
	add_child(_detail)

	var back := Button.new()
	back.text = "← GERİ"
	back.position = Vector2(60, 1700)
	back.custom_minimum_size = Vector2(300, 110)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): get_tree().change_scene_to_file(HOME))
	add_child(back)

	_refresh_currency()
	if not _chars.is_empty():
		_on_select(_chars[0].id)

func _refresh_currency() -> void:
	_currency.text = "💰 Altın: %d      💎 Kristal: %d" % [Meta.gold, Meta.crystal]

func _on_select(char_id: String) -> void:
	_selected_id = char_id
	_rebuild_detail()

func _rebuild_detail() -> void:
	for ch in _detail.get_children():
		ch.queue_free()
	var c: Character = _by_id[_selected_id]
	var max_hp: int = c.max_hp + Meta.hp_bonus(c.id)

	_detail.add_child(_stat("%s" % c.display_name, 52, Color(0.99, 0.85, 0.4)))
	_detail.add_child(_stat("Element: %s" % ", ".join(c.element_pair), 34))
	_detail.add_child(_stat("Max Can: %d  (taban %d + bonus %d)" % [max_hp, c.max_hp, Meta.hp_bonus(c.id)], 34))
	_detail.add_child(_stat("Hasar bonusu: +%d (flat)" % Meta.power_bonus(c.id), 34))
	_detail.add_child(_stat("Hız: %d" % c.speed, 34))

	_detail.add_child(_upgrade_row("CAN", MetaProgress.Track.HP))
	_detail.add_child(_upgrade_row("HASAR", MetaProgress.Track.POWER))

func _upgrade_row(track_name: String, track: int) -> HBoxContainer:
	var c: Character = _by_id[_selected_id]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	var lvl := Meta.track_level(c.id, track)
	var cost := Meta.upgrade_cost(c.id, track)
	h.add_child(_stat("%s  [Lv %d]" % [track_name, lvl], 40))
	var b := Button.new()
	b.text = "YÜKSELT  (%d 💰)" % cost
	b.custom_minimum_size = Vector2(440, 110)
	b.add_theme_font_size_override("font_size", 36)
	b.disabled = not Meta.can_afford(c.id, track)
	b.pressed.connect(_on_upgrade.bind(track))
	h.add_child(b)
	return h

func _on_upgrade(track: int) -> void:
	if Meta.buy_upgrade(_selected_id, track):
		_refresh_currency()
		_rebuild_detail()

func _stat(text: String, fsize: int, color: Color = Color(0.92, 0.92, 0.95)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	return l
