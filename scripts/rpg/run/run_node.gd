extends RefCounted
class_name RunNode

# Bir run (bölüm) içindeki tek düğüm. Saf veri. RunManager bunları sırayla gezer.
#   BATTLE : normal savaş. data["enemies"] = Enemy dizisi.
#   CHOICE : seçim (rün draftı / boost). data boş; seçenekler RunManager'da üretilir.
#   BOSS   : boss savaşı. data["enemies"] = Enemy dizisi (boss + maiyeti).
#   REWARD : run sonu ödülü. data["gold"] = kazanılan para. Terminal düğüm.

enum Type { BATTLE, CHOICE, BOSS, REWARD }

var type: int
var data: Dictionary

func _init(p_type: int, p_data: Dictionary = {}) -> void:
	type = p_type
	data = p_data

func is_battle() -> bool:
	return type == Type.BATTLE or type == Type.BOSS

func enemies() -> Array:
	return data.get("enemies", [])
