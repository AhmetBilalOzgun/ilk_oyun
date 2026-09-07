extends RefCounted
class_name TimeScaleController

# Kombo derinliği → timeScale hesabı. Saf: Engine'e yazmaz (adaptörün işi).
# Merdiven RuneDB'den gelir. İlk rün her zaman tam hızda (depth 0 → 1.0);
# yavaşlama KAZANILAN bir durumdur, varsayılan değil.

var _db: RuneDB
var current: float = 1.0

func _init(db: RuneDB) -> void:
	_db = db

func compute(depth: int, overdrive_active: bool) -> float:
	current = _db.time_scale_for(depth, overdrive_active)
	return current
