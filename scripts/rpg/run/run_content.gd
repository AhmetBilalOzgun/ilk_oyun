extends RefCounted
class_name RunContent

# MVP run içeriği (dikey dilim). Saf/headless. Tek başlangıç karakteri = KOR BÜYÜCÜ
# (Ember form). Storm rünü alınca PLAZMA'ya dönüşür (bkz spec Part 5). Combo matrisi
# ve 3-büyücü genişliği PARK EDİLDİ — MVP yalnız Ember->Plazma dilimini kablolar.
#
# Run deseni: [BATTLE, CHOICE] × 3 -> BOSS -> REWARD (spec Part 12).
# Aktif girdi (tap/swipe) her becerinin input_sequence'inde; PERFECT/GOOD/MISS ->
# hasar çarpanı (fail-soft, bkz InputEvaluator + BattleConfig).

const S := InputSequence.Step   # kısaltma: S.TAP, S.SWIPE_LEFT ...

# --- Formlar ------------------------------------------------------------------

# Ember (Kor): direkt ateş hasarı + YAKMA pasifi (temel büyü küçük DoT taşır).
# Girdi: SOL -> SAĞ -> DOKUN.
static func ember_form() -> MageForm:
	var f := MageForm.new("ember", "Kor Büyücü")
	f.sprite_key = "wizard_fire"
	f.element_effect = "Burn"
	f.passive_hook = "burn_on_hit"
	f.passive_amount = 0.20
	f.passive_text = "Ateş hasarı hedefi yakar (sonraki tur %20 tekrar hasar)."

	var basic := Skill.new("ember_bolt", "Ateş Oku", "ember", 20, "Projectile", "Burn")
	basic.dot_fraction = 0.20   # kimlik pasifi: yakma
	basic.input_sequence = _seq([S.SWIPE_LEFT, S.SWIPE_RIGHT, S.TAP])
	f.basic_spell = basic

	var ult := Skill.new("inferno", "İnferno", "ember", 60, "Area", "Burn")
	ult.requires_charge = true
	ult.aoe = true
	ult.dot_fraction = 0.35     # güçlü yakma
	ult.input_sequence = _seq([S.SWIPE_UP, S.TAP, S.TAP])
	f.ultimate = ult
	return f

# Plazma (Ember + Storm): şok hasarı + STUN'lı ultimate. Girdi: DOKUN -> DOKUN -> SAĞ.
static func plasma_form() -> MageForm:
	var f := MageForm.new("plasma", "Plazma Büyücü")
	f.sprite_key = "wizard_arcane"
	f.element_effect = "Shatter"
	f.passive_hook = "plasma_overload"
	f.passive_amount = 0.0
	f.passive_text = "Plazma darbeleri zırhı kırıp ekstra hasar verir."

	var basic := Skill.new("plasma_bolt", "Plazma Oku", "storm", 26, "Beam", "Shatter")
	basic.input_sequence = _seq([S.TAP, S.TAP, S.SWIPE_RIGHT])
	f.basic_spell = basic

	var ult := Skill.new("plasma_storm", "Plazma Fırtınası", "storm", 70, "Storm", "Shatter")
	ult.requires_charge = true
	ult.aoe = true
	ult.applies_stun = true     # tüm düşmanları sersemletir
	ult.input_sequence = _seq([S.SWIPE_RIGHT, S.SWIPE_RIGHT, S.TAP])
	f.ultimate = ult
	return f

static func _seq(steps: Array, window := 1.4) -> InputSequence:
	return InputSequence.new(steps, window)

# --- Katalog (formlar + dönüşümler + relic'ler) -------------------------------
static func catalog() -> SkillCatalog:
	var cat := SkillCatalog.new()
	cat.add_form(ember_form())
	cat.add_form(plasma_form())
	cat.add_transform("ember", "storm", "plasma")   # Ember + Storm -> Plazma
	for r in relic_catalog():
		cat.add_relic(r)
	return cat

# Run boyu aktif olabilecek relic kartları. Her biri bir HOOK taşır; motor hook
# noktalarında sorar (bkz Relic / RelicSet / TurnManager / BattleDamage).
static func relic_catalog() -> Array:
	return [
		Relic.new("wildfire", "Yaban Ateşi", "Yanma yandaki düşmana da sıçrar.", "burn_spread", 0.0),
		Relic.new("overcharge", "Aşırı Yük", "Şimşekten sonraki büyün %50 güçlü.", "post_storm_amp", 1.5),
		Relic.new("permafrost", "Kalıcı Don", "Donmuş düşmana 2 kat hasar.", "frozen_amp", 2.0),
		Relic.new("capacitor", "Kondansatör", "Ultin %50 daha hızlı dolar.", "charge_gain_mult", 1.5),
		Relic.new("ember_zeal", "Köz", "Yanma hasarı %60 daha güçlü.", "dot_amp", 1.6),
		Relic.new("bloodpact", "Kan Bağı", "Verdiğin hasarın %25'i kadar iyileşirsin.", "lifesteal", 0.25),
		Relic.new("executioner", "İnfaz", "Az canlı düşmana 1.6 kat hasar.", "execute", 1.6),
		Relic.new("piercer", "Delici", "Düşmanın savunmasını deler.", "shatter_pierce", 0.0),
	]

# --- Karakter + başlangıç formu -----------------------------------------------

# MVP: tek başlangıç karakteri (Kor Büyücü / Ember). Diğer büyücüler park edildi.
static func party() -> Array:
	var m := Character.new()
	m.id = "ember"; m.display_name = "Kor Büyücü"
	m.element_pair = ["Ateş"]; m.max_hp = 90; m.speed = 14
	return [m]

static func single_party(_char_id := "") -> Array:
	return party()

static func character_by_id(_char_id := "") -> Character:
	return party()[0]

# char_id -> başlangıç formu (catalog'un form örnekleriyle aynı kimlik).
static func start_forms(cat: SkillCatalog) -> Dictionary:
	return {"ember": cat.form("ember")}

# --- Seviyeler: her biri [BATTLE,CHOICE]×3 -> BOSS -> REWARD -------------------
const LEVEL_COUNT := 20

static func level_count() -> int:
	return LEVEL_COUNT

static func level_name(i: int) -> String:
	return "Seviye %d" % (i + 1)

static func reward_gold(i: int) -> int:
	return 80 + 40 * i

static func reward_crystal(i: int) -> int:
	return 1 + int(i / 5)

# Ölçek: seviyeyle yumuşak büyür (20 seviyeli eğri).
static func hp_scale(i: int) -> float:
	return 1.0 + 0.18 * i

static func dmg_scale(i: int) -> float:
	return 1.0 + 0.12 * i

# i. seviyenin düğüm listesi: 3 normal savaş + boss.
static func stage_nodes(i: int) -> Array:
	var hs := hp_scale(i)
	var ds := dmg_scale(i)
	var b1: Array = []
	var b2: Array = []
	var b3: Array = []

	if i < 3:
		# Tutorial seviyeleri (1-3)
		b1 = [_mob("grunt", hs, ds, 0)]
		b2 = [_mob("grunt", hs, ds, 0), _mob("archer", hs, ds, 1)]
		b3 = [_mob("brute", hs, ds, 0)]
	elif i < 8:
		# Tier 1 (4-8): Karışık birlikler
		b1 = [_mob("grunt", hs, ds, 0), _mob("runner", hs, ds, 1)]
		b2 = [_mob("archer", hs, ds, 0), _mob("brute", hs, ds, 1)]
		b3 = [_mob("grunt", hs, ds, 0), _mob("wraith", hs, ds, 1)]
	elif i < 14:
		# Tier 2 (9-14): Zırhlı ve hızlı düşmanlar
		b1 = [_mob("brute", hs, ds, 0), _mob("archer", hs, ds, 1)]
		b2 = [_mob("wraith", hs, ds, 0), _mob("mauler", hs, ds, 1)]
		b3 = [_mob("runner", hs, ds, 0), _mob("mauler", hs, ds, 1), _mob("archer", hs, ds, 2)]
	else:
		# Tier 3 & Tier 4 (15-20): Elit düşman ordusu
		b1 = [_mob("mauler", hs, ds, 0), _mob("wraith", hs, ds, 1)]
		b2 = [_mob("brute", hs, ds, 0), _mob("archer", hs, ds, 1), _mob("runner", hs, ds, 2)]
		b3 = [_mob("mauler", hs, ds, 0), _mob("wraith", hs, ds, 1), _mob("brute", hs, ds, 2)]

	var boss := [_boss_for_level(i, hs, ds)]
	return StageDef.linear([b1, b2, b3], boss, reward_gold(i))

# --- Düşman arketipleri -------------------------------------------------------
# [ad, base_hp, base_dmg, speed, saldırı_adı, carrier, weakness, resist]
const _ARCH := {
	"grunt":  ["Goblin", 34, 6, 12, "Kesik", "Projectile", [], []],
	"archer": ["Okçu", 30, 9, 16, "Ok", "Projectile", [], []],
	"brute":  ["Taş Golem", 70, 10, 8, "Ezme", "Projectile", [], ["Burn"]],
	"runner": ["Swarm Kurt", 24, 7, 20, "Isırık", "Projectile", [], []],
	"wraith": ["Gölge Hayalet", 45, 12, 18, "Tırpan", "Beam", ["Shatter"], []],
	"mauler": ["Yıkıcı Ayı", 110, 16, 6, "Darbe", "Projectile", [], ["Burn"]],
}

# Untyped Array -> Array[String] (Enemy prop tipli).
static func _typed(src: Array) -> Array[String]:
	var out: Array[String] = []
	for s in src:
		out.append(String(s))
	return out

static func _mob(arch: String, hp_s: float, dmg_s: float, idx: int) -> Enemy:
	var a: Array = _ARCH.get(arch, _ARCH["grunt"])
	var e := Enemy.new()
	e.id = "%s_%d" % [arch, idx]
	e.display_name = a[0]
	e.max_hp = int(round(a[1] * hp_s))
	e.speed = a[3]
	e.weakness_effects = _typed(a[6])
	e.resist_effects = _typed(a[7])
	var atks: Array[Skill] = [_atk(arch + "_atk", a[4], a[2], a[5], dmg_s)]
	e.skills = atks
	return e

static func _boss_for_level(i: int, hp_s: float, dmg_s: float) -> Enemy:
	var e := Enemy.new()
	e.id = "boss_%d" % i
	if i < 4:
		e.display_name = "Kül Ejderi"
		e.max_hp = int(round(140 * hp_s))
		e.speed = 16
		e.skills = [_atk("boss_atk", "Alev Nefesi", 14, "Area", dmg_s)]
	elif i < 9:
		e.display_name = "Savaş Lordu"
		e.max_hp = int(round(220 * hp_s))
		e.speed = 14
		e.skills = [_atk("boss_atk2", "Baltalı Saldırı", 18, "Projectile", dmg_s)]
	elif i < 14:
		e.display_name = "Golem Kralı"
		e.max_hp = int(round(340 * hp_s))
		e.speed = 10
		e.resist_effects = _typed(["Burn"])
		e.skills = [_atk("boss_atk3", "Deprem", 22, "Storm", dmg_s)]
	elif i < 19:
		e.display_name = "Fırtına Efendisi"
		e.max_hp = int(round(480 * hp_s))
		e.speed = 18
		e.weakness_effects = _typed(["Shatter"])
		e.skills = [_atk("boss_atk4", "Yıldırım Kasırgası", 28, "Storm", dmg_s)]
	else:
		e.display_name = "Boşluk Devi"
		e.max_hp = int(round(750 * hp_s))
		e.speed = 20
		e.skills = [_atk("boss_atk5", "Boşluk Kıyameti", 36, "Area", dmg_s)]
	return e

static func _atk(id: String, name: String, dmg: int, carrier: String, s: float) -> Skill:
	return Skill.new(id, name, "", int(round(dmg * s)), carrier, "")
