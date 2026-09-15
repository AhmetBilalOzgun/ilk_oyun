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

	# İlk açılış: büyücü seçilmemişse varsayılan olarak ilkini seç (kalıcı).
	if Meta.selected_character == "":
		Meta.select_character(RunContent.party()[0].id)

	var title := _label("RÜN BÜYÜCÜSÜ", 72, Vector2(60, 240))
	title.add_theme_color_override("font_color", Color(0.99, 0.85, 0.4))
	add_child(title)

	var active := RunContent.character_by_id(Meta.selected_character)
	var who := _label("Büyücü: %s (%s)" % [active.display_name, ", ".join(active.element_pair)], 40, Vector2(60, 360))
	who.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	add_child(who)

	_build_mastery_bar()

	var box := VBoxContainer.new()
	box.position = Vector2(180, 560)
	box.add_theme_constant_override("separation", 40)
	add_child(box)

	box.add_child(_button("OYNA", _on_play))
	var endless_txt := "♾ ENDLESS"
	if Meta.endless_best_depth > 0:
		endless_txt += "  (en iyi: %d kat)" % Meta.endless_best_depth
	box.add_child(_button(endless_txt, _on_endless))
	box.add_child(_button("KARAKTERLER", _on_characters))
	box.add_child(_button("KRİSTAL → ALTIN", _on_convert))
	box.add_child(_button("KRİSTAL AL (test +5)", _on_buy_crystal))
	box.add_child(_button("ÇIKIŞ", func(): get_tree().quit()))

func _refresh_currency() -> void:
	_currency.text = "💰 Altın: %d      💎 Kristal: %d" % [Meta.gold, Meta.crystal]

# Battle-pass mastery çubuğu: oynadıkça dolar; dolunca sıradaki ödül açılır.
func _build_mastery_bar() -> void:
	var group := Control.new()
	group.name = "MasteryGroup"
	group.set_anchors_preset(Control.PRESET_FULL_RECT)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(group)

	var m: int = Meta.mastery
	var nxt: int = MasteryTrack.next_need(m)
	var prev: int = MasteryTrack.prev_need(m)
	var frac: float = 1.0 if nxt < 0 else float(m - prev) / float(max(1, nxt - prev))
	var done: int = Meta.claimed_tiers
	var total: int = MasteryTrack.tier_count()

	var head := _label("🎖 MASTERY  %d/%d" % [done, total], 36, Vector2(60, 440))
	head.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	group.add_child(head)

	var bar := ProgressBar.new()
	bar.position = Vector2(60, 476)
	bar.custom_minimum_size = Vector2(840, 30)
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = frac
	bar.show_percentage = false
	group.add_child(bar)

	var nxt_text: String = "Tüm ödüller açıldı 🎉" if nxt < 0 else \
		"Sıradaki: %s  (%d / %d)" % [MasteryTrack.next_label(m), m, nxt]
	var sub := _label(nxt_text, 30, Vector2(60, 512))
	sub.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	group.add_child(sub)

	# Hak edilmiş ödül varsa: elle TOPLA butonu (aç -> topla dopamin anı). Her basış 1 tier.
	if Meta.claimable_count() > 0:
		var claim := Button.new()
		claim.text = "🎁 TOPLA (%d)" % Meta.claimable_count()
		claim.position = Vector2(920, 470)
		claim.custom_minimum_size = Vector2(280, 60)
		claim.add_theme_font_override("font", PIXEL_FONT)
		claim.add_theme_font_size_override("font_size", 30)
		claim.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		claim.pressed.connect(_on_claim)
		claim.name = "ClaimButton"
		group.add_child(claim)
		# Dikkat çeksin: nabız.
		var tw := create_tween().set_loops()
		tw.tween_property(claim, "modulate", Color(1.4, 1.2, 0.6, 1.0), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(claim, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE)

# TOPLA: sıradaki tier ödülünü uygula + gösterisi. Sonra mastery barı + parayı tazele.
func _on_claim() -> void:
	var reward := Meta.claim_next()
	if reward.is_empty():
		return
	_show_reward_popup(String(reward.get("label", "Ödül")))
	_rebuild_mastery()
	_refresh_currency()

# Mevcut mastery UI elemanlarını (bar/başlık/alt/TOPLA) kaldırıp yeniden çiz.
func _rebuild_mastery() -> void:
	for n in get_children():
		if n is Control and n.name == "MasteryGroup":
			n.queue_free()
	_build_mastery_bar()

# Ödül gösterisi: ekran ortasında büyük kart, ~1.6s sonra söner.
func _show_reward_popup(label: String) -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.06, 0.05, 0.12, 0.92)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var l := _label("🎁 AÇILDI\n\n%s" % label, 64, Vector2(0, 700))
	l.size = Vector2(get_viewport_rect().size.x, 400)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	panel.add_child(l)
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(panel, "modulate:a", 0.0, 0.35)
	tw.tween_callback(panel.queue_free)

const BATTLE := "res://scenes/battle.tscn"

func _on_play() -> void:
	Meta.endless_run = false
	get_tree().change_scene_to_file(LEVEL_SELECT)

# Endless: seviye seçmeden doğrudan sonsuz run'a gir (ritim sürekli hızlanır).
func _on_endless() -> void:
	Meta.endless_run = true
	get_tree().change_scene_to_file(BATTLE)

func _on_characters() -> void:
	get_tree().change_scene_to_file(CHARACTERS)

func _on_convert() -> void:
	if Meta.convert_crystal(1):
		_refresh_currency()

func _on_buy_crystal() -> void:
	Meta.add_crystal(5)   # IAP stub
	_refresh_currency()

const PIXEL_FONT = preload("res://assets/fonts/PixelifySans-Bold.ttf")

func _label(text: String, fsize: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", PIXEL_FONT)
	l.add_theme_font_size_override("font_size", int(round(fsize * 0.5)))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1.0))
	return l

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(720, 110)
	b.add_theme_font_override("font", PIXEL_FONT)
	b.add_theme_font_size_override("font_size", 34)
	b.pressed.connect(cb)
	return b
