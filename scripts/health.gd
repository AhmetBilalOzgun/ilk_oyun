extends Node

# Yeniden kullanılabilir can bileşeni. Bir birime (Player/Enemy) child olarak
# eklenir, HP durumunu tutar ve hasar/ölüm sinyalleri yayar.
# Görsel yok — çizim HealthBar'ın işi.

signal damaged(amount: int, hp: int)
signal died

@export var max_hp: int = 100
var hp: int

func _ready() -> void:
	hp = max_hp

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = max(0, hp - amount)
	damaged.emit(amount, hp)
	if hp == 0:
		died.emit()

func heal(amount: int) -> void:
	if hp <= 0:
		return
	hp = min(max_hp, hp + amount)
	damaged.emit(-amount, hp)

func is_alive() -> bool:
	return hp > 0

func ratio() -> float:
	return float(hp) / float(max_hp) if max_hp > 0 else 0.0
