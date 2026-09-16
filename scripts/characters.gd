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
	var look := Theme.new()
	look.set_color("font_color", "Label", GameLook.INK)
	look.set_color("font_color", "Button", GameLook.INK)
	look.set_stylebox("normal", "Button", GameLook.panel())
	theme = look
	_chars = RunContent.party()
	for c in _chars:
		_by_id[c.id] = c

	GameLook.background(self, 1)
	GameLook.card(self, Rect2(35, 300, 1010, 1360))

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
		GameLook.button(b)
		row.add_child(b)

	# Detay paneli.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 330)
	scroll.size = Vector2(960, 1290)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 24)
	scroll.add_child(_detail)

	var back := Button.new()
	back.text = "← GERİ"
	back.position = Vector2(60, 1700)
	back.custom_minimum_size = Vector2(300, 110)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): get_tree().change_scene_to_file(HOME))
	GameLook.button(back)
	add_child(back)

	_refresh_currency()
	# Panel aktif büyücüde açılsın (yoksa ilki).
	var start_id: String = Meta.selected_character
	if start_id == "" or not _by_id.has(start_id):
		start_id = _chars[0].id if not _chars.is_empty() else ""
	if start_id != "":
		_on_select(start_id)

func _refresh_currency() -> void:
	_currency.text = "💰 Altın: %d      💎 Kristal: %d" % [Meta.gold, Meta.crystal]

func _on_select(char_id: String) -> void:
	_selected_id = char_id
	_rebuild_detail()

func _rebuild_detail() -> void:
	for ch in _detail.get_children():
		_detail.remove_child(ch)
		ch.queue_free()
	var c: Character = _by_id[_selected_id]
	var max_hp: int = c.max_hp + Meta.hp_bonus(c.id)

	var is_active: bool = Meta.selected_character == c.id
	var title := "%s%s" % [c.display_name, "   ★ AKTİF" if is_active else ""]
	_detail.add_child(_stat(title, 52, GameLook.CORAL.darkened(0.4)))
	_detail.add_child(_stat("Element: %s" % ", ".join(c.element_pair), 34))
	_detail.add_child(_stat(_kit_text(c.id), 30, GameLook.TEAL.darkened(0.35)))
	_detail.add_child(_stat("Max Can: %d  (taban %d + bonus %d)" % [max_hp, c.max_hp, Meta.hp_bonus(c.id)], 34))
	_detail.add_child(_stat("Hasar bonusu: +%d (flat)" % Meta.power_bonus(c.id), 34))
	_detail.add_child(_stat("Hız: %d" % c.speed, 34))

	# SEÇ butonu — bu büyücüyü aktif yap (zaten aktifse kilitli).
	var sel := Button.new()
	sel.text = "★ AKTİF BÜYÜCÜ" if is_active else "SEÇ (aktif yap)"
	sel.custom_minimum_size = Vector2(440, 110)
	sel.add_theme_font_size_override("font_size", 36)
	sel.disabled = is_active
	sel.pressed.connect(_on_select_active)
	GameLook.button(sel)
	_detail.add_child(sel)

	_detail.add_child(_upgrade_row("CAN", MetaProgress.Track.HP))
	_detail.add_child(_upgrade_row("HASAR", MetaProgress.Track.POWER))

	# Ekipman (kalıcı, tüm karakterlerce paylaşılan): al + tak.
	_detail.add_child(_stat("— EKİPMAN —", 40, GameLook.CORAL.darkened(0.4)))
	for e in Equipment.catalog():
		_detail.add_child(_equipment_row(e))

func _equipment_row(e: Equipment) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	var owned: bool = Meta.is_owned(e.id)
	var equipped: bool = Meta.equipped_in(e.slot) == e.id
	h.add_child(_stat("[%s] %s — %s" % [Equipment.slot_name(e.slot), e.display_name, e.description], 26))
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 90)
	b.add_theme_font_size_override("font_size", 30)
	if equipped:
		b.text = "★ TAKILI"; b.disabled = true
	elif owned:
		b.text = "TAK"; b.pressed.connect(_on_equip.bind(e.id))
	else:
		b.text = "AL (%d 💰)" % e.cost
		b.disabled = Meta.gold < e.cost
		b.pressed.connect(_on_buy_equipment.bind(e.id, e.cost))
	GameLook.button(b, GameLook.TEAL, 28)
	h.add_child(b)
	return h

func _on_buy_equipment(item_id: String, cost: int) -> void:
	if Meta.buy_equipment(item_id, cost):
		Meta.equip(Equipment.by_id(item_id))   # aldıysan hemen tak (kolaylık)
		_refresh_currency()
		_rebuild_detail()

func _on_equip(item_id: String) -> void:
	if Meta.equip(Equipment.by_id(item_id)):
		_rebuild_detail()

# Büyücünün başlangıç formu + Storm rünüyle açılan dönüşüm (tutorial ipucu).
func _kit_text(char_id: String) -> String:
	var cat := RunContent.catalog()
	var start: Dictionary = RunContent.start_forms(cat)
	var form: MageForm = start.get(char_id, null)
	if form == null:
		return "Form: ?"
	# Sabit jest dizisi (◀▶●) KALDIRILDI — dizi her cast'te rastgele üretiliyor. Onun
	# yerine formu bir cümlede anlatan pasif metni göster.
	var line := "Form: %s" % form.display_name
	if form.passive_text != "":
		line += "\n%s" % form.passive_text
	# Bu formu dönüştüren bir rün var mı?
	for rune_id in cat.acquirable_runes():
		var to_id := cat.transform_for(form.id, rune_id)
		if to_id != "":
			line += "\n+%s Rününü Al → %s ol" % [rune_id.capitalize(), cat.form(to_id).display_name]
			break
	return line

func _on_select_active() -> void:
	Meta.select_character(_selected_id)
	_rebuild_detail()

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
	GameLook.button(b, GameLook.TEAL, 28)
	h.add_child(b)
	return h

func _on_upgrade(track: int) -> void:
	if Meta.buy_upgrade(_selected_id, track):
		_refresh_currency()
		_rebuild_detail()

func _stat(text: String, fsize: int, color: Color = GameLook.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	return l
