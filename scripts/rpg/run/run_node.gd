extends RefCounted
class_name RunNode

# Bir run (bölüm) içindeki tek düğüm. Saf veri. RunManager bunları GRAF (DAG) olarak
# gezer: her düğüm `next` ile bir sonraki sütundaki erişilebilir düğüm indekslerini
# tutar. Tek haleften -> otomatik ilerler (lineer); çok haleften -> ROUTE seçimi
# (StS harita). `col`/`row` yalnız harita çizimi (battle.gd) içindir.
#   BATTLE : normal savaş. data["enemies"] = Enemy dizisi.
#   ELITE  : risk/reward savaşı — daha güçlü düşman + daha yüksek orb ödülü.
#   CHOICE : seçim (orb board + kart). Savaş sonrası otomatik gelir; seçenekler
#            RunManager'da üretilir. Haritada çizilmez (ara düğüm).
#   BOSS   : boss savaşı. data["enemies"] = Enemy dizisi.
#   HEAL   : dinlenme odası — partiyi iyileştirir (data["amount"]). Savaş yok.
#   TREASURE: hazine odası — bedava relic + orb (data["relic"], data["orbs"]). Savaş yok.
#   REWARD : run sonu ödülü. data["gold"] = kazanılan para. Terminal düğüm.

enum Type { BATTLE, CHOICE, BOSS, REWARD, ELITE, HEAL, TREASURE }

var type: int
var data: Dictionary
var next: Array[int] = []   # sonraki sütundaki erişilebilir düğüm indeksleri (DAG kenarları)
var col: int = 0            # harita sütunu (UI)
var row: int = 0            # sütun içi satır (UI)

func _init(p_type: int, p_data: Dictionary = {}) -> void:
	type = p_type
	data = p_data

func is_battle() -> bool:
	return type == Type.BATTLE or type == Type.BOSS or type == Type.ELITE

func is_elite() -> bool:
	return type == Type.ELITE

func is_rest() -> bool:
	return type == Type.HEAL

func is_treasure() -> bool:
	return type == Type.TREASURE

# Haritada çizilen "oda" mı (CHOICE/REWARD ara/terminal, çizilmez).
func is_room() -> bool:
	return type != Type.CHOICE and type != Type.REWARD

func enemies() -> Array:
	return data.get("enemies", [])
