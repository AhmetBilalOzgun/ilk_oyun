extends RefCounted
class_name MasteryTrack

# Battle-pass tarzı KALICI ilerleme yolu (kullanıcı yönü 2026-09-15). Oyuncu oynadıkça
# mastery XP kazanır; barlar dolunca SIRAYLA ödüller açılır — arketipler (build yönleri)
# + eşyalar + para. Açılan arketip CHOICE havuzunda çıkmaya hak kazanır (rastgele değil,
# HAK EDİLMİŞ). Saf/headless veri; MetaProgress bunu okur.
#
# Ödül tipleri:
#   "archetype" (value=arketip id) — CHOICE havuzunda çıkabilir hale gelir
#   "equipment" (value=ekipman id) — owned_equipment'a eklenir
#   "gold" / "crystal" (value=miktar)

# Kümülatif mastery eşiği + o tier'ın ödülü. Sıra = açılış sırası.
const TIERS := [
	{"need": 40,   "type": "archetype", "value": "burn_build",      "label": "Yakma / Kör Etme"},
	{"need": 110,  "type": "equipment", "value": "ember_boots",     "label": "👢 Köz Çizme"},
	{"need": 200,  "type": "archetype", "value": "execute_build",   "label": "Kritik formlar"},
	{"need": 320,  "type": "gold",      "value": 200,               "label": "💰 200 Altın"},
	{"need": 470,  "type": "archetype", "value": "explosion_build", "label": "Patlayıcı formlar"},
	{"need": 650,  "type": "equipment", "value": "flame_armor",     "label": "🛡 Alev Zırhı"},
	{"need": 900,  "type": "crystal",   "value": 5,                 "label": "💎 5 Kristal"},
]

static func tier_count() -> int:
	return TIERS.size()

static func tier(i: int) -> Dictionary:
	return TIERS[i] if i >= 0 and i < TIERS.size() else {}

# Bu mastery ile hak edilen tier sayısı (claim edilmiş olsun olmasın).
static func reached_tiers(mastery: int) -> int:
	var n := 0
	for t in TIERS:
		if mastery >= int(t["need"]):
			n += 1
	return n

# Bir sonraki tier'ın gerektirdiği kümülatif mastery (hepsi bittiyse -1).
static func next_need(mastery: int) -> int:
	for t in TIERS:
		if mastery < int(t["need"]):
			return int(t["need"])
	return -1

# Bir önceki (son hak edilmiş) tier'ın eşiği — bar dolum oranı için (yoksa 0).
static func prev_need(mastery: int) -> int:
	var p := 0
	for t in TIERS:
		if mastery >= int(t["need"]):
			p = int(t["need"])
		else:
			break
	return p

# Bir sonraki açılacak ödülün etiketi ("" = hepsi açık).
static func next_label(mastery: int) -> String:
	for t in TIERS:
		if mastery < int(t["need"]):
			return String(t["label"])
	return ""
