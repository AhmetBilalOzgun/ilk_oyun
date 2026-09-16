extends Control

const BATTLE := "res://scenes/battle.tscn"
const HOME := "res://scenes/home.tscn"

func _ready() -> void:
	GameLook.background(self, 1)
	var title := GameLook.label("YOLCULUĞUNU SEÇ", 58)
	title.position = Vector2(70, 80)
	add_child(title)
	var sub := GameLook.label("5 diyar · 20 bölüm · Bir sürü küçük keşif", 30)
	sub.position = Vector2(70, 160)
	add_child(sub)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 250)
	scroll.size = Vector2(960, 1430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 28)
	scroll.add_child(box)
	for world in range(5):
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", GameLook.panel())
		box.add_child(card)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 16)
		card.add_child(content)
		var thumb := TextureRect.new()
		thumb.texture = GameLook.backdrop(world)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.custom_minimum_size = Vector2(870, 220)
		content.add_child(thumb)
		content.add_child(GameLook.label("%02d  %s" % [world + 1, GameLook.WORLD_NAMES[world]], 36))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		content.add_child(row)
		for offset in range(4):
			var i := world * 4 + offset
			var unlocked: bool = Meta.is_level_unlocked(i)
			var cleared: bool = i < Meta.cleared_levels
			var b := Button.new()
			b.text = "%02d\n%s" % [i + 1, "BİTTİ" if cleared else ("OYNA" if unlocked else "KİLİTLİ")]
			b.custom_minimum_size = Vector2(200, 112)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			GameLook.button(b, GameLook.TEAL if cleared else GameLook.CORAL, 28)
			b.disabled = not unlocked
			b.pressed.connect(_on_level.bind(i))
			row.add_child(b)
		content.add_child(GameLook.label("Bölüm %d–%d  ·  %d–%d altın" % [world * 4 + 1, world * 4 + 4, RunContent.reward_gold(world * 4), RunContent.reward_gold(world * 4 + 3)], 24))
	var back := Button.new()
	back.text = "← ANA MENÜ"
	back.position = Vector2(60, 1740)
	back.size = Vector2(960, 100)
	GameLook.button(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file(HOME))
	add_child(back)

func _on_level(i: int) -> void:
	Meta.endless_run = false
	Meta.selected_level = i
	get_tree().change_scene_to_file(BATTLE)
