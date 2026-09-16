extends Control

# KODEKS / büyü kitabı ekranı. Oyuncunun run'larda KARŞILAŞTIĞI içeriği (form, arketip,
# relik, düşman) toplar: keşfedilen = isim + açıklama, keşfedilmemiş = 🔒 ???. Kaybedilen
# run bile boşa gitmez — keşif kalıcı ilerlemedir (makro motivasyon: koleksiyon). İçerik
# listesi CodexData'dan (RunContent türevi), keşif durumu Meta.discovered'dan gelir.

const HOME := "res://scenes/home.tscn"

func _ready() -> void:
	GameLook.background(self)
	var title := GameLook.label("📖 KODEKS", 60)
	title.position = Vector2(80, 70)
	title.size.x = 920
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var disc := CodexData.discovered_count(Meta.discovered)
	var total := CodexData.total_count()
	var sub := GameLook.label("KEŞİF:  %d / %d" % [disc, total], 36)
	sub.position = Vector2(80, 160)
	sub.size.x = 920
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(70, 240)
	scroll.custom_minimum_size = Vector2(940, 1420)
	scroll.size = Vector2(940, 1420)
	add_child(scroll)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 900
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)

	for cat in CodexData.categories():
		var entries: Array = cat["entries"]
		var cd := 0
		for e in entries:
			if Meta.is_discovered(e["key"]):
				cd += 1
		var head := GameLook.label("— %s  (%d/%d) —" % [cat["title"], cd, entries.size()], 34)
		col.add_child(head)
		for e in entries:
			if Meta.is_discovered(e["key"]):
				col.add_child(GameLook.label("✔ %s" % e["name"], 28))
				if String(e["desc"]) != "":
					col.add_child(GameLook.label("      %s" % e["desc"], 22))
			else:
				col.add_child(GameLook.label("🔒 ???", 28))

	var back := Button.new()
	back.text = "🏠 GERİ"
	back.custom_minimum_size = Vector2(740, 90)
	GameLook.button(back)
	back.position = Vector2(170, 1700)
	back.pressed.connect(func(): get_tree().change_scene_to_file(HOME))
	add_child(back)
