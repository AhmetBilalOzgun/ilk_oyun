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
	for a in ember_archetypes():
		cat.add_archetype(a)
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

# Ember (Kor) build arketip havuzu — makro motivasyon: "bu run'da NASIL bir büyücü?"
# DIŞLAYICI SEÇİM: run'da yalnız BİRİ alınır, diğerleri kilitlenir (bkz
# ChoiceGenerator._archetype_candidates). Her biri farklı bir YÖN + oynanış tarzı:
#   🔥 Alev   = DoT (yakma yığılır/yayılır)      — alan orta
#   🎯 İnfaz  = tek hedef (az canlıyı bitir+lifesteal) — alan yok
#   💥 Patlama = alan (saldırılar yayılır + ölüm zinciri) — tek hedef zayıf
# Kimlik-swap'ı DEĞİŞTİRMEZ, üstüne biner. basic_splash + on_kill_aoe yeni hook'lar;
# gerisi mevcut relic hook'ları. Aynı 3 model ilerde Plazma için de.
static func ember_archetypes() -> Array:
	return [
		Archetype.new("burn_build", "Alev",
			"Yakma yığılır, komşuya yayılır ve daha sert vurur.", "ember", "Alev", [
				Relic.new("burn_build_amp", "", "", "burn_dmg_amp", 1.6),
				Relic.new("burn_build_dot", "", "", "dot_amp", 1.5),
				Relic.new("burn_build_spread", "", "", "burn_spread", 0.0),
			], "🔥", Color(1.25, 0.72, 0.55)),      # sıcak kızıl-turuncu
		Archetype.new("execute_build", "İnfaz",
			"Tek hedefe kilit: az canlıyı bitirir, verdiğin hasardan can çekersin.", "ember", "Nişancı", [
				Relic.new("execute_build_exec", "", "", "execute", 2.5),
				Relic.new("execute_build_leech", "", "", "lifesteal", 0.15),
			], "🎯", Color(1.2, 1.05, 0.6)),        # keskin altın-sarı
		Archetype.new("explosion_build", "Patlama",
			"Normal saldırıların alana yayılır; ölen düşman zincir patlar.", "ember", "Patlayan", [
				Relic.new("explosion_build_splash", "", "", "basic_splash", 0.5),
				Relic.new("explosion_build_aoe", "", "", "on_kill_aoe", 0.6),
			], "💥", Color(1.3, 0.6, 0.45)),        # patlayıcı kor-kırmızı
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

# Build cadence: arketip (build-değişim) teklifi yalnız build-bölümlerinde açılır;
# kalan bölümler stat-meta grind'i (içerik maliyeti dengesi, kullanıcı kararı 2026-09-15).
# "Her 3-5 bölümde bir" -> her 4 bölüm, tutorial sonrası: i = 3, 7, 11, 15, 19.
const BUILD_LEVEL_EVERY := 4
static func is_build_level(i: int) -> bool:
	return i >= 3 and (i - 3) % BUILD_LEVEL_EVERY == 0

# Ölçek: seviyeyle yumuşak büyür (20 seviyeli eğri).
static func hp_scale(i: int) -> float:
	return 1.0 + 0.18 * i

static func dmg_scale(i: int) -> float:
	return 1.0 + 0.12 * i

# i. seviyenin LİNEER düğüm listesi (geriye dönük uyumluluk / test). Dallanmalı harita
# için campaign_map. 3 normal savaş + (i>=3) elite + boss.
static func stage_nodes(i: int) -> Array:
	var hs := hp_scale(i)
	var ds := dmg_scale(i)
	var sets := _tier_sets(i, hs, ds)
	var boss := [_boss_for_level(i, hs, ds)]
	# Tutorial sonrası (i>=3) boss'tan önce bir ELITE (risk/reward) savaşı; tutorial'da yok.
	var elite: Array = _elite_set(i, hs, ds) if i >= 3 else []
	return StageDef.linear(sets, boss, reward_gold(i), elite)

# Seviyeye göre 3 normal savaş düşman seti [b1,b2,b3] (tier eğrisi). stage_nodes + harita paylaşır.
static func _tier_sets(i: int, hs: float, ds: float) -> Array:
	if i < 3:
		return [[_mob("grunt", hs, ds, 0)],
			[_mob("grunt", hs, ds, 0), _mob("archer", hs, ds, 1)],
			[_mob("brute", hs, ds, 0)]]
	elif i < 8:
		return [[_mob("grunt", hs, ds, 0), _mob("runner", hs, ds, 1)],
			[_mob("archer", hs, ds, 0), _mob("brute", hs, ds, 1)],
			[_mob("grunt", hs, ds, 0), _mob("wraith", hs, ds, 1)]]
	elif i < 14:
		return [[_mob("brute", hs, ds, 0), _mob("archer", hs, ds, 1)],
			[_mob("wraith", hs, ds, 0), _mob("mauler", hs, ds, 1)],
			[_mob("runner", hs, ds, 0), _mob("mauler", hs, ds, 1), _mob("archer", hs, ds, 2)]]
	else:
		return [[_mob("mauler", hs, ds, 0), _mob("wraith", hs, ds, 1)],
			[_mob("brute", hs, ds, 0), _mob("archer", hs, ds, 1), _mob("runner", hs, ds, 2)],
			[_mob("mauler", hs, ds, 0), _mob("wraith", hs, ds, 1), _mob("brute", hs, ds, 2)]]

# ELITE düşman seti: normal savaştan belirgin daha güçlü (ekstra ölçek). Build'i sınar;
# yenince orb ödülü battle.gd'de artırılır (ELITE_ORB_MULT). Şimdilik sade (doküman §3).
const ELITE_HP_SCALE := 1.7
const ELITE_DMG_SCALE := 1.3
static func _elite_set(i: int, hs: float, ds: float) -> Array:
	var ehs := hs * ELITE_HP_SCALE
	var eds := ds * ELITE_DMG_SCALE
	return [_mob("mauler", ehs, eds, 0), _mob("wraith", hs, ds, 1)]

# --- Dallanmalı harita (StS sütun DAG) ---------------------------------------
# Campaign: giriş savaşı -> dallanan orta sütun(lar) -> boss -> reward. Tutorial (i<3)
# küçük harita (1 dallanma). Endless: sonsuz uzayan sütunlar, boss/reward yok (extend).

const HEAL_ROOM_AMOUNT := 40      # dinlenme odası parti iyileştirmesi
const TREASURE_ORBS := 8          # hazine odası bedava orb

# i. seviyenin dallanmalı haritası. rng deterministik.
static func campaign_map(i: int, rng: RandomNumberGenerator) -> RunMap:
	var m := RunMap.new()
	var hs := hp_scale(i)
	var ds := dmg_scale(i)
	# Giriş sütunu: tek savaş (StS gibi tek başlangıç, sonra dallanır).
	var entry := m.add_room(_battle_room(i, hs, ds, rng, 0, 0))
	m.push_column([entry])
	# Orta sütun(lar): tutorial 1, sonrası 3. Genişlik 2-3, tür karışık (i>=3 elite/heal/hazine).
	var mid_cols := 1 if i < 3 else 3
	var prev: Array = [entry]
	for c in range(mid_cols):
		var width := 2 if (i < 3 or rng.randf() < 0.5) else 3
		var col_rooms: Array = []
		for r in range(width):
			var kind := _pick_room_kind(i, c, mid_cols, rng)
			col_rooms.append(m.add_room(_room_node(m, kind, i, hs, ds, rng, m.next_col, r)))
		m.push_column(col_rooms)
		_wire(m, prev, col_rooms, rng)
		prev = col_rooms
	# Boss sütunu (tek) + reward (gizli terminal).
	var boss := RunNode.new(RunNode.Type.BOSS, {"enemies": [_boss_for_level(i, hs, ds)]})
	boss.col = m.next_col
	var bidx := m.add_room(boss)
	m.push_column([bidx])
	_wire(m, prev, [bidx], rng)
	var reward := RunNode.new(RunNode.Type.REWARD, {"gold": reward_gold(i)})
	var ridx := m.add_hidden(reward)
	boss.next = RunMap._ti([ridx])
	return m

# Endless harita: birkaç başlangıç sütunu + extender (bitince RunManager uzatır).
static func endless_map(rng: RandomNumberGenerator) -> RunMap:
	var m := RunMap.new()
	m.extender = func(mp: RunMap, r: RandomNumberGenerator, d: int) -> void:
		_extend_endless(mp, r, d)
	# Giriş savaşı + 2 sütun; gerisi oynadıkça extend edilir.
	var entry := m.add_room(_battle_room(0, hp_scale(0), dmg_scale(0), rng, 0, 0))
	m.push_column([entry])
	_extend_endless(m, rng, 0)
	return m

# Endless: son sütundan 2 yeni sütun ekle (zorluk sütun indeksiyle ölçeklenir).
static func _extend_endless(m: RunMap, rng: RandomNumberGenerator, _depth: int) -> void:
	var prev: Array = m.last_rooms.duplicate()
	for c in range(2):
		var lvl := m.next_col            # mutlak sütun -> zorluk seviyesi gibi kullan
		var hs := hp_scale(lvl)
		var ds := dmg_scale(lvl)
		var width := 2 + (1 if rng.randf() < 0.4 else 0)
		var col_rooms: Array = []
		for r in range(width):
			var kind := _pick_room_kind(maxi(3, lvl), c, 99, rng)  # endless: her zaman tam havuz
			col_rooms.append(m.add_room(_room_node(m, kind, lvl, hs, ds, rng, m.next_col, r)))
		m.push_column(col_rooms)
		_wire(m, prev, col_rooms, rng)
		prev = col_rooms

# Sütun odalarını bir sonraki sütuna bağla: her oda 1-2 komşuya, her hedef en az 1 girişli.
static func _wire(m: RunMap, from_rooms: Array, to_rooms: Array, rng: RandomNumberGenerator) -> void:
	var adj: Dictionary = {}
	for fi in range(from_rooms.size()):
		adj[fi] = []
	for fi in range(from_rooms.size()):
		var tc := _proj(fi, from_rooms.size(), to_rooms.size())
		adj[fi].append(to_rooms[tc])
		if to_rooms.size() > 1 and rng.randf() < 0.45:
			var alt := clampi(tc + (1 if rng.randf() < 0.5 else -1), 0, to_rooms.size() - 1)
			if to_rooms[alt] not in adj[fi]:
				adj[fi].append(to_rooms[alt])
	# Kapsama: erişilemez hedef kalmasın.
	var covered: Dictionary = {}
	for fi in adj:
		for ti in adj[fi]:
			covered[ti] = true
	for tj in range(to_rooms.size()):
		var ti: int = to_rooms[tj]
		if not covered.has(ti):
			var fi := _proj(tj, to_rooms.size(), from_rooms.size())
			adj[fi].append(ti)
	for fi in range(from_rooms.size()):
		m.link_room(from_rooms[fi], adj[fi])

# i indeksini [0,n) -> [0,m) merkez izdüşümü (dallanma hizası).
static func _proj(i: int, n: int, mm: int) -> int:
	if mm <= 1 or n <= 1:
		return 0
	return int(round(float(i) / float(n - 1) * float(mm - 1)))

# Oda türü seçimi: ağırlıklı — çoğu SAVAŞ, i>=3'te ELITE/HEAL/HAZİNE. Boss'a yakın sütunlar
# (endless'ta hep) daha çok elite. İlk sütun daha güvenli.
static func _pick_room_kind(i: int, col: int, _total: int, rng: RandomNumberGenerator) -> int:
	if i < 3:
		return RunNode.Type.BATTLE
	var roll := rng.randf()
	if roll < 0.60:
		return RunNode.Type.BATTLE
	elif roll < 0.78:
		return RunNode.Type.ELITE
	elif roll < 0.90:
		return RunNode.Type.HEAL
	else:
		return RunNode.Type.TREASURE

# Türe göre oda düğümü kur (col/row atanır). SAVAŞ/ELİT enemy taşır, HEAL/TREASURE veri.
static func _room_node(m: RunMap, kind: int, i: int, hs: float, ds: float, rng: RandomNumberGenerator, col: int, row: int) -> RunNode:
	var node: RunNode
	match kind:
		RunNode.Type.ELITE:
			node = RunNode.new(RunNode.Type.ELITE, {"enemies": _elite_set(i, hs, ds)})
		RunNode.Type.HEAL:
			node = RunNode.new(RunNode.Type.HEAL, {"amount": HEAL_ROOM_AMOUNT})
		RunNode.Type.TREASURE:
			var relics := relic_catalog()
			var relic = relics[rng.randi_range(0, relics.size() - 1)]
			node = RunNode.new(RunNode.Type.TREASURE, {"relic": relic, "orbs": TREASURE_ORBS})
		_:
			node = _battle_room(i, hs, ds, rng, col, row)
	node.col = col
	node.row = row
	return node

# Rastgele bir normal savaş odası (tier setlerinden birini seçer).
static func _battle_room(i: int, hs: float, ds: float, rng: RandomNumberGenerator, col: int, row: int) -> RunNode:
	var sets := _tier_sets(i, hs, ds)
	var enemies: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var node := RunNode.new(RunNode.Type.BATTLE, {"enemies": enemies})
	node.col = col
	node.row = row
	return node

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
