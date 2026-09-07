extends RefCounted
class_name RuneDB

# Motordan bağımsız tuning veri deposu. Node/Engine/Time'a dokunmaz.
# combo_config.json'u parse eder VEYA testler için ham dict'ten kurulur.
# Saf RefCounted → headless instantiate edilebilir (health.gd/enemy.gd deseninin
# saf hâli, ama motor zamanı okumadan).

const DEFAULT_PATH := "res://data/combo_config.json"

# Tek bir rünün statik tanımı.
class RuneDef:
	var id: String
	var carrier: String
	var effect         # String veya null (strike'ın etkisi yok)
	var base_damage: int
	func _init(p_id: String, p_carrier: String, p_effect, p_base: int) -> void:
		id = p_id
		carrier = p_carrier
		effect = p_effect
		base_damage = p_base

var runes: Dictionary = {}          # id -> RuneDef
var fusions: Array = []             # [{a, b, result}]
var combo_multiplier_per_rune: float = 1.6
var time_scale_ladder: Dictionary = {}   # "1".."4","overdrive" -> float
var window_ladder_sec: Dictionary = {}   # "1".."3" -> float
var combo_chain_gap_sec: float = 0.30
var casting_cap_sec: float = 1.2
var charge_hits_to_fill: int = 30
var overdrive_duration_sec: float = 1.5
var overdrive_damage_multiplier: float = 2.0
var chain_break_on: String = "damage"
var weakness_wrong_effect_multiplier: float = 0.40
var shape_to_rune: Dictionary = {}       # çizim shape id -> rune id

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
	for fz in d.get("fusions", []):
		var pair: Array = fz.get("pair", [])
		if pair.size() == 2:
			db.fusions.append({"a": pair[0], "b": pair[1], "result": fz.get("result", "")})
	db.combo_multiplier_per_rune = float(d.get("combo_multiplier_per_rune", 1.6))
	db.time_scale_ladder = d.get("time_scale_ladder", {})
	db.window_ladder_sec = d.get("window_ladder_sec", {})
	db.combo_chain_gap_sec = float(d.get("combo_chain_gap_sec", 0.30))
	db.casting_cap_sec = float(d.get("casting_cap_sec", 1.2))
	var charge: Dictionary = d.get("charge", {})
	db.charge_hits_to_fill = int(charge.get("hits_to_fill", 30))
	var od: Dictionary = d.get("overdrive", {})
	db.overdrive_duration_sec = float(od.get("duration_sec", 1.5))
	db.overdrive_damage_multiplier = float(od.get("damage_multiplier", 2.0))
	var chain: Dictionary = d.get("chain", {})
	db.chain_break_on = str(chain.get("break_on", "damage"))
	db.weakness_wrong_effect_multiplier = float(d.get("weakness_wrong_effect_multiplier", 0.40))
	db.shape_to_rune = d.get("shape_to_rune", {})
	return db

func get_rune(id: String) -> RuneDef:
	return runes.get(id, null)

func has_rune(id: String) -> bool:
	return runes.has(id)

# İki etki için füzyon sonucu; eşleşme yoksa "" döner. Sıra bağımsız.
func fusion_for(effect_a, effect_b) -> String:
	for fz in fusions:
		if (fz.a == effect_a and fz.b == effect_b) or (fz.a == effect_b and fz.b == effect_a):
			return fz.result
	return ""

# Kombo derinliğine göre timeScale. Merdiven rün ORDİNALİ ile anahtarlı
# (Rün 1 = 1.0, Rün 2 = 0.50 ...). depth = atılmış rün sayısı, sıradaki rünün
# ordinali depth+1. Yani depth 0 (ilk rünü çiziyoruz) -> ordinal 1 -> 1.0 tam hız.
# 4+ için son basamak. overdrive_active ise özel "overdrive" basamağı.
func time_scale_for(depth: int, overdrive_active: bool) -> float:
	if overdrive_active:
		return float(time_scale_ladder.get("overdrive", 0.10))
	var ordinal := depth + 1
	var key := str(ordinal)
	if time_scale_ladder.has(key):
		return float(time_scale_ladder[key])
	# ordinal tablodan büyük (Rün 5+): en yüksek sayısal basamağı kullan
	var best := 1.0
	var best_k := 0
	for k in time_scale_ladder.keys():
		if k.is_valid_int() and int(k) <= ordinal and int(k) >= best_k:
			best_k = int(k)
			best = float(time_scale_ladder[k])
	return best

# Kombo derinliğine göre pencere süresi (sn, ölçeklenmemiş). 3+ son basamak.
func window_for(depth: int) -> float:
	if depth <= 0:
		return 0.0
	var key := str(depth)
	if window_ladder_sec.has(key):
		return float(window_ladder_sec[key])
	var best := 0.0
	for k in window_ladder_sec.keys():
		if k.is_valid_int() and int(k) <= depth:
			best = float(window_ladder_sec[k])
	return best
