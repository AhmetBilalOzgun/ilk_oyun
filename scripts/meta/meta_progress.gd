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

# --- Mastery (battle-pass) ---
# Oyuncu oynadıkça mastery XP kazanır; MasteryTrack barları dolunca SIRAYLA ödüller
# açılır (arketipler + eşya + para). Açılan arketip CHOICE havuzunda çıkabilir hale
# gelir (bkz ChoiceGenerator + RunState.unlocked_archetypes). Kazanç savaş başına.
const MASTERY_PER_WIN := 12           # normal savaş zaferi
const MASTERY_ELITE_BONUS := 15       # ELITE savaş ek mastery
const MASTERY_BOSS_BONUS := 20        # BOSS savaş ek mastery

# --- Adaptif ritim zorluğu (piano tiles hızı) ---
# Oyun reflekse dayalı: 20 de 60 yaş da zevk alsın diye piano tiles HIZI oyuncunun
# gerçek oynayışına göre kendini ayarlar. İki hız ölçeği (skill) tutulur:
#   rhythm_skill  = KALICI global profil (kaydedilir) — yavaş öğrenir, "bu oyuncu
#                   genel olarak ne kadar hızlı" der.
#   _rhythm_session = OTURUM içi (RAM, kaydedilmez) — hızlı tepki verir: kötü gün
#                   ya da eli başkasına verme durumunu birkaç cast'te yakalar.
# Efektif hız çarpanı = ikisinin harmanı (rhythm_speed_scale). Kombo bitince
# record_rhythm_result çağrılır: skor hedefin üstündeyse hızlan, altındaysa yavaşla.
const RHYTHM_SKILL_DEFAULT := 1.0     # yeni oyuncu: nötr çarpan (bugünkü davranış)
const RHYTHM_SKILL_MIN := 0.6         # en yavaş (yeni/60 yaş/kötü gün)
const RHYTHM_SKILL_MAX := 1.6         # en hızlı (usta refleks)
const RHYTHM_TARGET_SCORE := 0.82     # hedef kombo skoru (0..1): tuttur => hız sabit
const RHYTHM_GLOBAL_GAIN := 0.020     # kalıcı skill kazancı/cast (yavaş, uzun vadeli)
const RHYTHM_SESSION_GAIN := 0.080    # oturum skill kazancı/cast (hızlı tepki)
const RHYTHM_SESSION_WEIGHT := 0.6    # efektif hız: %60 oturum + %40 kalıcı
const RHYTHM_BROKE_ERR := -0.30       # kombo kırıldı: en az bu kadar "çok zor" sinyali

enum Track { HP, POWER }

var gold: int = 0
var crystal: int = 0
var cleared_levels: int = 0           # bitmiş seviye sayısı (açık = i <= cleared_levels)
var upgrades: Dictionary = {}         # char_id -> {"hp":int, "power":int}
var selected_character: String = ""   # oyun başı seçilen büyücü; "" -> ilk
var selected_level: int = 0           # level_select -> battle arası taşıyıcı
var endless_run: bool = false         # home -> battle taşıyıcı: bu run endless mi (kaydedilmez)
var endless_best_depth: int = 0       # endless en iyi kat (kalıcı, home'da gösterilir)
var owned_equipment: Array = []       # sahip olunan ekipman id'leri
var equipped: Dictionary = {}         # str(slot) -> ekipman id (slot başına bir parça)
var persist: bool = true              # false -> save/load devre dışı (test)
var rhythm_skill: float = RHYTHM_SKILL_DEFAULT  # KALICI ritim hız skill'i (kaydedilir)
var _rhythm_session: float = -1.0     # OTURUM ritim skill'i (RAM; <0 => henüz tohumlanmadı)
var mastery: int = 0                  # battle-pass XP (oynadıkça birikir, kaydedilir)
var claimed_tiers: int = 0            # uygulanmış tier ödülü sayısı (çifte ödül önler)
var unlocked_archetypes: Array = []   # açılan arketip id'leri (CHOICE'ta çıkabilir)

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

# --- Mastery (battle-pass) ---

# Mastery XP ekle (savaş zaferinde). Ödül UYGULAMAZ — oyuncu ana ekranda ELLE TOPLAR
# (claim_next). Böylece "aç -> topla" dopamin anı ve ödül gösterisi olur. Kalıcı kaydeder.
func add_mastery(n: int) -> void:
	mastery += max(0, n)
	save_game()

# Hak edilmiş ama henüz toplanmamış tier sayısı (home'da "TOPLA (n)" butonu bunu okur).
func claimable_count() -> int:
	return maxi(0, MasteryTrack.reached_tiers(mastery) - claimed_tiers)

# Sıradaki hak edilmiş tier ödülünü uygula (arketip/eşya/para) ve tier dict'ini döndür
# (UI ödül gösterisi için). Toplanacak ödül yoksa {} döner. Çifte ödül yok (claimed_tiers).
func claim_next() -> Dictionary:
	if claimable_count() <= 0:
		return {}
	var t := MasteryTrack.tier(claimed_tiers)
	_apply_tier_reward(t)
	claimed_tiers += 1
	save_game()
	return t

func _apply_tier_reward(t: Dictionary) -> void:
	match String(t.get("type", "")):
		"archetype":
			var aid := String(t["value"])
			if aid not in unlocked_archetypes:
				unlocked_archetypes.append(aid)
		"equipment":
			var eid := String(t["value"])
			if eid not in owned_equipment:
				owned_equipment.append(eid)
		"gold":
			gold += int(t["value"])
		"crystal":
			crystal += int(t["value"])

func is_archetype_unlocked(id: String) -> bool:
	return id in unlocked_archetypes

# --- Seviye ilerlemesi ---

func is_level_unlocked(i: int) -> bool:
	return i <= cleared_levels

func clear_level(i: int) -> void:
	if i >= cleared_levels:
		cleared_levels = i + 1
	save_game()

# --- Ekipman (kalıcı) ---

func is_owned(item_id: String) -> bool:
	return item_id in owned_equipment

# Altınla ekipman al. Yeter altın yoksa / zaten sahipse false.
func buy_equipment(item_id: String, cost: int) -> bool:
	if is_owned(item_id) or gold < cost:
		return false
	gold -= cost
	owned_equipment.append(item_id)
	save_game()
	return true

# Sahip olunan bir ekipmanı slot'una tak (aynı slot'taki eskiyi değiştirir).
func equip(item: Equipment) -> bool:
	if item == null or not is_owned(item.id):
		return false
	equipped[str(item.slot)] = item.id
	save_game()
	return true

func equipped_in(slot: int) -> String:
	return String(equipped.get(str(slot), ""))

# Takılı tüm ekipman parçaları (Equipment listesi).
func equipped_list() -> Array:
	var out: Array = []
	for key in equipped.keys():
		var e := Equipment.by_id(String(equipped[key]))
		if e != null:
			out.append(e)
	return out

# Takılı ekipmandan gelen düz stat bonusları (savaş kurulumunda uygulanır).
func equipped_hp_bonus() -> int:
	var total := 0
	for e in equipped_list():
		if e.hook == "max_hp_flat":
			total += int(e.amount)
	return total

func equipped_speed_bonus() -> int:
	var total := 0
	for e in equipped_list():
		if e.hook == "speed_flat":
			total += int(e.amount)
	return total

# --- Adaptif ritim zorluğu ---

# Oturum skill'i ilk kullanımda kalıcı profilden tohumlanır (usta oyuncu baştan
# sürünmesin). Oturum RAM'de yaşar; uygulama kapanınca sıfırlanır (yeni oturum).
func _rhythm_session_skill() -> float:
	if _rhythm_session < 0.0:
		_rhythm_session = rhythm_skill
	return _rhythm_session

# Bir sonraki cast'in piano tiles hız çarpanı: oturum (hızlı) + kalıcı (yavaş) harmanı.
# battle.gd bunu wave hız ölçeğiyle çarpar. Aralık [MIN, MAX].
func rhythm_speed_scale() -> float:
	var blended: float = rhythm_skill * (1.0 - RHYTHM_SESSION_WEIGHT) \
		+ _rhythm_session_skill() * RHYTHM_SESSION_WEIGHT
	return clampf(blended, RHYTHM_SKILL_MIN, RHYTHM_SKILL_MAX)

# Kombo bitince çağrılır (combo_score 0..1, broke: kombo kırıldı mı). Skoru hedefe
# göre değerlendirir; iki skill EMA'sını (kalıcı yavaş + oturum hızlı) günceller ve
# kalıcıyı kaydeder. İyi oynadı => hızlan; zorlandı/kırıldı => yavaşla (fail-soft).
func record_rhythm_result(combo_score: float, broke: bool) -> void:
	var err: float = clampf(combo_score, 0.0, 1.0) - RHYTHM_TARGET_SCORE
	if broke:
		err = minf(err, RHYTHM_BROKE_ERR)   # kırılma => en az bu kadar "çok zor"
	rhythm_skill = clampf(rhythm_skill + err * RHYTHM_GLOBAL_GAIN,
		RHYTHM_SKILL_MIN, RHYTHM_SKILL_MAX)
	_rhythm_session = clampf(_rhythm_session_skill() + err * RHYTHM_SESSION_GAIN,
		RHYTHM_SKILL_MIN, RHYTHM_SKILL_MAX)
	save_game()

# --- Kalıcılık ---

func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"crystal": crystal,
		"cleared_levels": cleared_levels,
		"upgrades": upgrades,
		"selected_character": selected_character,
		"owned_equipment": owned_equipment,
		"equipped": equipped,
		"rhythm_skill": rhythm_skill,
		"mastery": mastery,
		"claimed_tiers": claimed_tiers,
		"unlocked_archetypes": unlocked_archetypes,
		"endless_best_depth": endless_best_depth,
	}

func from_dict(d: Dictionary) -> void:
	gold = int(d.get("gold", 0))
	crystal = int(d.get("crystal", 0))
	cleared_levels = int(d.get("cleared_levels", 0))
	upgrades = d.get("upgrades", {})
	selected_character = String(d.get("selected_character", ""))
	owned_equipment = d.get("owned_equipment", [])
	equipped = d.get("equipped", {})
	rhythm_skill = clampf(float(d.get("rhythm_skill", RHYTHM_SKILL_DEFAULT)),
		RHYTHM_SKILL_MIN, RHYTHM_SKILL_MAX)
	mastery = int(d.get("mastery", 0))
	claimed_tiers = int(d.get("claimed_tiers", 0))
	unlocked_archetypes = d.get("unlocked_archetypes", [])
	endless_best_depth = int(d.get("endless_best_depth", 0))

# Aktif büyücüyü seç (oyun başı / karakterler ekranı) + kalıcı kaydet.
func select_character(char_id: String) -> void:
	selected_character = char_id
	save_game()

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
