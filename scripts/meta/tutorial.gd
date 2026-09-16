extends RefCounted
class_name Tutorial

# İLK 5 BÖLÜM = DENEYEREK ÖĞREN tutorial'ı (durduran text-box YOK).
# Bu saf katman yalnız "hangi bölümde ritim ne kadar kolay" tavanını ve bağlamsal
# ipucu metinlerini tutar. battle.gd bunları okur: ritim hızını/uzunluğunu tavanlar,
# ipuçlarını akıp giden _flash ile bir kez gösterir (bkz Meta.has_seen_hint).
#
# Tasarım: her bölüm TEK yeni şeyi güvenli bir bağlamda öğretir. Metin oyunu durdurmaz;
# oyuncu mekaniği kendi elleyerek keşfeder, ipucu yalnız yön verir.
#   L1 (idx 0): ritim = tek yavaş nota, dev pencere -> "çizgide DOKUN"
#   L2 (idx 1): swipe yönü + PERFECT bonusu
#   L3 (idx 2): savaş-arası ORB board + kart seçimi (ekonomi)
#   L4 (idx 3): kombo uzar, hız normale yaklaşır (pekiştirme)
#   L5 (idx 4): ilk BUILD seçimi (arketip/relic) — sonra tutorial kapanır

const TUTORIAL_LEVELS := 5    # campaign selected_level 0..4 tutorial kapsamında

# Bu bölüm tutorial kapsamında mı? (endless/challenge modda çağıran taraf zaten gate'ler.)
static func is_tutorial(level: int) -> bool:
	return level >= 0 and level < TUTORIAL_LEVELS

# Ritim zorluk TAVANI: {combo_len, speed_cap}. battle bunu doğal değerlerle min'ler —
# yalnız kolaylaştırır, asla zorlaştırmaz. Tutorial dışı: geniş (etkisiz) değerler.
static func rhythm_caps(level: int, _node_index: int = 0) -> Dictionary:
	match level:
		0: return {"combo_len": 1, "speed_cap": 0.60}   # tek yavaş nota, en geniş pencere
		1: return {"combo_len": 2, "speed_cap": 0.72}   # swipe tanıtımı, hâlâ yavaş
		2: return {"combo_len": 2, "speed_cap": 0.88}   # ekonomi bölümü; ritim rahat kalsın
		3: return {"combo_len": 3, "speed_cap": 1.00}   # kombo uzar, hız normale gelir
		4: return {"combo_len": 4, "speed_cap": 1.15}   # serbeste yakın; son yumuşak adım
	return {"combo_len": 99, "speed_cap": 99.0}         # tutorial dışı: tavan yok

# Bağlamsal ipucu metinleri (bir kez gösterilir; battle Meta.has_seen_hint ile gate'ler).
# Boş string = ipucu yok. Anahtarlar battle.gd'de sabit.
const HINTS := {
	"rhythm": "TAM ÇİZGİDEYKEN DOKUN",
	"swipe": "OK YÖNÜNE KAYDIR",
	"perfect": "TAM ZAMANINDA = MÜKEMMEL = DAHA ÇOK HASAR",
	"charge": "ŞARJ DOLDU — ULTİMATE HAZIR!",
	"choice": "SAVAŞ ARASI — GÜÇLEN",
	"orb": "ORB'LARI TAHTAYA DÖK (DOKUN-BIRAK)",
	"cards": "BİR KART SEÇ — KALICI GÜÇ",
	"build": "BUILD SEÇİMİ — YÖNÜNÜ BELİRLE",
}

static func hint(key: String) -> String:
	return String(HINTS.get(key, ""))
