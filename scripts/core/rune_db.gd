extends RefCounted
class_name RuneDB

# Motordan bağımsız rün tuning deposu. Node/Engine/Time'a dokunmaz.
# combo_config.json'u parse eder VEYA testler için ham dict'ten kurulur.
# Turn-based dönüşümde sadeleşti: rün tanımı + şekil->rün eşlemesi. Eski kombo
# alanları (füzyon, timeScale/pencere merdiveni, şarj, overdrive) kaldırıldı —
# kombo motoru silindi; şarj barı artık savaş çekirdeğinde (Combatant/TurnManager).

const DEFAULT_PATH := "res://data/combo_config.json"

# Tek bir rünün statik tanımı.
class RuneDef:
	var id: String
	var carrier: String
	var effect         # String veya null
	var base_damage: int
	func _init(p_id: String, p_carrier: String, p_effect, p_base: int) -> void:
		id = p_id
		carrier = p_carrier
		effect = p_effect
		base_damage = p_base

var runes: Dictionary = {}          # id -> RuneDef
var shape_to_rune: Dictionary = {}  # çizim shape id -> rune id

static func load_from_file(path: String = DEFAULT_PATH) -> RuneDB:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("RuneDB: config açılamadı: %s" % path)
		return RuneDB.new()
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("RuneDB: config JSON geçersiz: %s" % path)
		return RuneDB.new()
	return from_dict(parsed)

static func from_dict(d: Dictionary) -> RuneDB:
	var db := RuneDB.new()
	for id in d.get("runes", {}).keys():
		var r: Dictionary = d["runes"][id]
		db.runes[id] = RuneDef.new(
			id, r.get("carrier", "Projectile"), r.get("effect", null),
			int(r.get("base_damage", 0)))
	db.shape_to_rune = d.get("shape_to_rune", {})
	return db

func get_rune(id: String) -> RuneDef:
	return runes.get(id, null)

func has_rune(id: String) -> bool:
	return runes.has(id)
