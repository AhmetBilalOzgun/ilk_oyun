extends Control

# Ana menü — Rün Büyücüsü.
# Oyna: savaş sahnesini yükler. Ayarlar: yer tutucu paneli açar/kapar
# (henüz mantık yok, dürüst "yakında"). Çıkış: uygulamadan çıkar.
# Butonların görseli Kenney "UI Pack: Pixel Adventure" 9-patch tile'ları
# (assets/ui/button_normal.png = ahşap+krem, button_pressed.png = kahve).

const GAME_SCENE := "res://scenes/battle.tscn"   # turn-based savaş (eski: scenes/main.tscn)

@onready var settings_panel: Control = $SettingsPanel


func _ready() -> void:
	settings_panel.visible = false


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible


func _on_settings_close_pressed() -> void:
	settings_panel.visible = false


func _on_quit_pressed() -> void:
	get_tree().quit()
