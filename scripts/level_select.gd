extends Control

# Seviye seçimi. RunContent.level_count() kadar seviye listelenir; sadece açık
# olanlar (Meta.is_level_unlocked) seçilebilir, gerisi KİLİTLİ. Seçince
# Meta.selected_level yazılır ve savaş sahnesine geçilir. Geri -> home.

const BATTLE := "res://scenes/battle.tscn"
const HOME := "res://scenes/home.tscn"

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.1, 0.15, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "SEVİYE SEÇ"
	title.position = Vector2(60, 80)
	title.add_theme_font_size_override("font_size", 64)
	add_child(title)

	var box := VBoxContainer.new()
	box.position = Vector2(180, 260)
	box.add_theme_constant_override("separation", 32)
	add_child(box)

	for i in range(RunContent.level_count()):
		var unlocked: bool = Meta.is_level_unlocked(i)
		var cleared: bool = i < Meta.cleared_levels
		var b := Button.new()
		var mark := "✓" if cleared else ("" if unlocked else "🔒")
		b.text = "%s  %s  (+%d💰 +%d💎)" % [
			RunContent.level_name(i), mark,
			RunContent.reward_gold(i), RunContent.reward_crystal(i)]
		b.custom_minimum_size = Vector2(720, 120)
		b.add_theme_font_size_override("font_size", 40)
		b.disabled = not unlocked
		b.pressed.connect(_on_level.bind(i))
		box.add_child(b)

	var back := Button.new()
	back.text = "← GERİ"
	back.custom_minimum_size = Vector2(300, 110)
	back.add_theme_font_size_override("font_size", 40)
	back.pressed.connect(func(): get_tree().change_scene_to_file(HOME))
	box.add_child(back)

func _on_level(i: int) -> void:
	Meta.selected_level = i
	get_tree().change_scene_to_file(BATTLE)
