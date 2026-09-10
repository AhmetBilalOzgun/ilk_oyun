extends Node
class_name MetaProgress

# Kalıcı meta ilerleme — autoload "Meta" olarak yüklenir, tüm sayfalar paylaşır.
# İki para: ALTIN (soft, her bölüm sonu kazanılır, tüm upgrade'ler bununla alınır)
# + KRİSTAL (premium, nadir, gerçek-parayla satılır — IAP MVP'de stub). Kristal
# istenildiğinde altına çevrilir (convert_crystal), ayrı bir sink yok.
#
# Upgrade: karakter başına 2 track — CAN (+max HP) ve HASAR (+flat hasar). Maliyet
# seviyeyle artar, altınla ödenir. Seviye ilerlemesi: cleared_levels; seviye i,
# i <= cleared_levels ise açık (0 hep açık).
#
# Kayıt: user://meta.json (JSON). persist=false -> dosya yazma (testler için).
# Saf veri + FileAccess; sahne/graf bilmez. Autoload Node olduğu için _ready'de
# otomatik yüklenir; testte MetaProgress.new() (tree dışı) _ready tetiklemez.

const SAVE_PATH := "user://meta.json"
const CRYSTAL_TO_GOLD := 100          # 1 kristal = 100 altın (çevrim oranı)

const HP_COST_BASE := 50
const POWER_COST_BASE := 75
const HP_STEP := 15                   # CAN seviyesi başına +max HP
const POWER_STEP := 4                 # HASAR seviyesi başına +flat hasar

enum Track { HP, POWER }

var gold: int = 0
var crystal: int = 0
var cleared_levels: int = 0           # bitmiş seviye sayısı (açık = i <= cleared_levels)
var upgrades: Dictionary = {}         # char_id -> {"hp":int, "power":int}
var selected_level: int = 0           # level_select -> battle arası taşıyıcı
var persist: bool = true              # false -> save/load devre dışı (test)

func _ready() -> void:
	load_game()

# --- Upgrade sorguları ---

func _key(track: int) -> String:
	return "hp" if track == Track.HP else "power"

func track_level(char_id: String, track: int) -> int:
	return upgrades.get(char_id, {}).get(_key(track), 0)

func upgrade_cost(char_id: String, track: int) -> int:
	var base: int = HP_COST_BASE if track == Track.HP else POWER_COST_BASE
	return base * (track_level(char_id, track) + 1)

func can_afford(char_id: String, track: int) -> bool:
	return gold >= upgrade_cost(char_id, track)

# Altınla bir track seviyesi al. Yeterli altın yoksa false döner (UI kilitler).
func buy_upgrade(char_id: String, track: int) -> bool:
	var cost := upgrade_cost(char_id, track)
	if gold < cost:
		return false
	gold -= cost
	var u: Dictionary = upgrades.get(char_id, {"hp": 0, "power": 0})
	var k := _key(track)
	u[k] = int(u.get(k, 0)) + 1
	upgrades[char_id] = u
	save_game()
	return true

func hp_bonus(char_id: String) -> int:
	return track_level(char_id, Track.HP) * HP_STEP

func power_bonus(char_id: String) -> int:
	return track_level(char_id, Track.POWER) * POWER_STEP

# --- Para ---

func add_gold(n: int) -> void:
	gold += n
	save_game()

func add_crystal(n: int) -> void:
	crystal += n
	save_game()

# Kristal -> altın çevrimi. n kristal kadar çevir (yeterli kristal yoksa false).
func convert_crystal(n: int) -> bool:
	if n <= 0 or crystal < n:
		return false
	crystal -= n
	gold += n * CRYSTAL_TO_GOLD
	save_game()
	return true

# --- Seviye ilerlemesi ---

func is_level_unlocked(i: int) -> bool:
	return i <= cleared_levels

func clear_level(i: int) -> void:
	if i >= cleared_levels:
		cleared_levels = i + 1
	save_game()

# --- Kalıcılık ---

func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"crystal": crystal,
		"cleared_levels": cleared_levels,
		"upgrades": upgrades,
	}

func from_dict(d: Dictionary) -> void:
	gold = int(d.get("gold", 0))
	crystal = int(d.get("crystal", 0))
	cleared_levels = int(d.get("cleared_levels", 0))
	upgrades = d.get("upgrades", {})

func save_game() -> void:
	if not persist:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()

func load_game() -> void:
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if data is Dictionary:
		from_dict(data)
