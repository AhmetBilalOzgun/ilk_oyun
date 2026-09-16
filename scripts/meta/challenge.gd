extends RefCounted
class_name Challenge

# Günlük / haftalık MEYDAN OKUMA: tarihten DETERMİNİSTİK seed türetir. Aynı gün oynayan
# herkes aynı seed'i -> aynı haritayı alır (async yarış). Skor RunScore ile ölçülür,
# Meta.daily_best / weekly_best tablosuna yazılır.
#
# ASYNC SOSYAL = STUB. Sunucu/leaderboard yok; percentile yerel bir lojistik eğriden
# üretilir ("oyuncuların %N'ini geçtin"). Gerçek sunucu tablosu Faz 4'te gelir; o zaman
# percentile() gerçek dağılımla değişir, çağrı yerleri aynı kalır. code_anchors: Challenge.

# Meydan okuma sabit bir zorlukta oynanır (build-bölüm: arketip teklifi açık olsun).
const CHALLENGE_LEVEL := 9

# Bugünün günlük seed'i: YYYYMMDD (deterministik, güne özgü). dt verilirse test için kullanılır.
static func daily_seed(dt: Dictionary = {}) -> int:
	var d := dt if not dt.is_empty() else Time.get_date_dict_from_system()
	return int(d.get("year", 2026)) * 10000 + int(d.get("month", 1)) * 100 + int(d.get("day", 1))

# Bu haftanın seed'i: yıl*100 + (yılın günü / 7). Aynı hafta -> aynı seed.
static func weekly_seed(dt: Dictionary = {}) -> int:
	var d := dt if not dt.is_empty() else Time.get_date_dict_from_system()
	return int(d.get("year", 2026)) * 100 + int(_day_of_year(d) / 7)

static func _day_of_year(d: Dictionary) -> int:
	var days := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var y := int(d.get("year", 2026))
	if (y % 4 == 0 and y % 100 != 0) or y % 400 == 0:
		days[1] = 29
	var n := int(d.get("day", 1))
	for m in range(int(d.get("month", 1)) - 1):
		n += days[m]
	return n

# ASYNC STUB: skoru 1..99 percentile'a çevirir. REF = "ortalama iyi run", SPREAD =
# dağılım genişliği. Lojistik: skor REF ise ~%50. Sunucu gelince burası değişir.
const REF := 500.0
const SPREAD := 260.0
static func percentile(score: int) -> int:
	var x := (float(score) - REF) / SPREAD
	var p := 1.0 / (1.0 + exp(-x))
	return clampi(int(round(p * 99.0)), 1, 99)

static func mode_label(mode: String) -> String:
	return "☀ GÜNLÜK MEYDAN" if mode == "daily" else "📅 HAFTALIK MEYDAN"
