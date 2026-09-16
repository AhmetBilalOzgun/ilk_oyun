extends Control

const LEVEL_SELECT := "res://scenes/level_select.tscn"
const CHARACTERS := "res://scenes/characters.tscn"
const BATTLE := "res://scenes/battle.tscn"
var _currency: Label
var _mastery: VBoxContainer

func _ready() -> void:
	GameLook.background(self)
	GameLook.card(self, Rect2(56, 52, 968, 100))
	_currency = GameLook.label("", 32)
	_currency.position = Vector2(88, 80)
	add_child(_currency)
	_refresh_currency()
	if Meta.selected_character == "":
		Meta.select_character(RunContent.party()[0].id)
	var title := GameLook.label("RÜN\nBÜYÜCÜSÜ", 88)
	title.position = Vector2(80, 220)
	title.size.x = 920
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var subtitle := GameLook.label("Küçük bir büyücü. Kocaman bir macera.", 30)
	subtitle.position = Vector2(80, 448)
	subtitle.size.x = 920
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	var hero := AnimatedSprite2D.new()
	hero.sprite_frames = GameLook.frames("fire")
	hero.position = Vector2(540, 760)
	hero.scale = Vector2.ONE * 1.7
	add_child(hero)
	hero.play("idle")
	var box := VBoxContainer.new()
	box.position = Vector2(170, 1010)
	box.add_theme_constant_override("separation", 20)
	add_child(box)
	box.add_child(_button("MACERAYA BAŞLA", _on_play, 120))
	box.add_child(_button("SONSUZ YOLCULUK  ·  Rekor %d" % Meta.endless_best_depth, _on_endless))
	box.add_child(_button("BÜYÜCÜ & EKİPMAN", _on_characters))
	GameLook.card(self, Rect2(100, 1410, 880, 280))
	_mastery = VBoxContainer.new()
	_mastery.position = Vector2(130, 1435)
	_mastery.size.x = 820
	_mastery.add_theme_constant_override("separation", 12)
	add_child(_mastery)
	_build_mastery_bar()
	var exchange :=  _button("1 KRİSTAL → 100 ALTIN", _on_convert, 70)
	exchange.position = Vector2(170, 1730)
	add_child(exchange)
	var utility := HBoxContainer.new()
	utility.position = Vector2(170, 1830)
	utility.add_theme_constant_override("separation", 20)
	add_child(utility)
	var crystal := _button("KRİSTAL AL (TEST)", _on_buy_crystal, 60)
	crystal.custom_minimum_size.x = 480
	GameLook.button(crystal, GameLook.TEAL, 24)
	utility.add_child(crystal)
	var leave := _button("ÇIKIŞ", func(): get_tree().quit(), 60)
	leave.custom_minimum_size.x = 240
	GameLook.button(leave, GameLook.TEAL, 24)
	utility.add_child(leave)

func _build_mastery_bar() -> void:
	for child in _mastery.get_children():
		_mastery.remove_child(child)
		child.queue_free()
	_mastery.add_child(GameLook.label("USTALIK YOLU  ·  %d / %d" % [Meta.claimed_tiers, MasteryTrack.tier_count()], 30))
	var nxt := MasteryTrack.next_need(Meta.mastery)
	var prev := MasteryTrack.prev_need(Meta.mastery)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(820, 28)
	bar.max_value = 1
	bar.value = 1.0 if nxt < 0 else float(Meta.mastery - prev) / maxi(1, nxt - prev)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", GameLook.panel(Color("dde6d4"), Color("a1b9a3")))
	bar.add_theme_stylebox_override("fill", GameLook.panel(GameLook.TEAL, GameLook.TEAL))
	_mastery.add_child(bar)
	var hint := "Tüm ödüller açıldı!" if nxt < 0 else "%s  ·  %d / %d" % [MasteryTrack.next_label(Meta.mastery), Meta.mastery, nxt]
	_mastery.add_child(GameLook.label(hint, 26))
	if Meta.claimable_count() > 0:
		var claim := _button("ÖDÜLÜ TOPLA (%d)" % Meta.claimable_count(), _on_claim, 64)
		claim.custom_minimum_size.x = 820
		_mastery.add_child(claim)

func _on_claim() -> void:
	var reward := Meta.claim_next()
	if reward.is_empty():
		return
	_build_mastery_bar()
	_refresh_currency()
	var popup := AcceptDialog.new()
	popup.title = "Yeni ödül!"
	popup.dialog_text = String(reward.get("label", "Ödül"))
	popup.confirmed.connect(popup.queue_free)
	popup.canceled.connect(popup.queue_free)
	add_child(popup)
	popup.popup_centered(Vector2i(650, 220))

func _refresh_currency() -> void:
	_currency.text = "ALTIN  %d                         KRİSTAL  %d" % [Meta.gold, Meta.crystal]

func _button(text: String, cb: Callable, height := 92) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(740, height)
	GameLook.button(b)
	b.pressed.connect(cb)
	return b

func _on_play() -> void:
	Meta.endless_run = false
	get_tree().change_scene_to_file(LEVEL_SELECT)

func _on_endless() -> void:
	Meta.endless_run = true
	get_tree().change_scene_to_file(BATTLE)

func _on_characters() -> void:
	get_tree().change_scene_to_file(CHARACTERS)

func _on_convert() -> void:
	if Meta.convert_crystal(1):
		_refresh_currency()

func _on_buy_crystal() -> void:
	Meta.add_crystal(5)  # Existing IAP test stub; no purchase performed.
	_refresh_currency()
