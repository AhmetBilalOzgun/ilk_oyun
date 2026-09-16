extends RefCounted
class_name CodexData

# Kodeks / büyü kitabı için KEŞFEDİLEBİLİR içerik master kataloğu. Saf/headless veri.
# İçerik tanımı tek kaynaktan (RunContent) türetilir — burada elle liste tutulmaz,
# böylece yeni form/arketip/relik eklenince kodeks otomatik büyür. Discovery anahtarları
# (Meta.discovered) burada üretilir; battle.gd karşılaşınca Meta.discover(key) çağırır,
# codex ekranı buradan tam listeyi + keşif sayacını okur. code_anchors: CodexData.

static func form_key(id: String) -> String:
	return "form:" + id

static func arch_key(form_id: String, id: String) -> String:
	return "arch:%s:%s" % [form_id, id]

static func relic_key(id: String) -> String:
	return "relic:" + id

static func enemy_key(display_name: String) -> String:
	return "enemy:" + display_name

static func forms() -> Array:
	var out: Array = []
	for f in RunContent.catalog().forms.values():
		out.append({"key": form_key(f.id), "name": f.display_name, "desc": f.passive_text})
	return out

static func archetypes() -> Array:
	var out: Array = []
	for a in RunContent.ember_archetypes():
		out.append({"key": arch_key("ember", a.id), "name": "%s (Kor)" % a.display_name, "desc": a.description})
	for a in RunContent.plasma_archetypes():
		out.append({"key": arch_key("plasma", a.id), "name": "%s (Plazma)" % a.display_name, "desc": a.description})
	return out

static func relics() -> Array:
	var out: Array = []
	for r in RunContent.relic_catalog():
		out.append({"key": relic_key(r.id), "name": r.display_name, "desc": r.description})
	return out

const ENEMY_NAMES := ["Goblin", "Okçu", "Taş Golem", "Swarm Kurt", "Gölge Hayalet", "Yıkıcı Ayı"]
const BOSS_NAMES := ["Kül Ejderi", "Savaş Lordu", "Golem Kralı", "Fırtına Efendisi", "Boşluk Devi"]

static func enemies() -> Array:
	var out: Array = []
	for n in ENEMY_NAMES:
		out.append({"key": enemy_key(n), "name": n, "desc": "Düşman"})
	for n in BOSS_NAMES:
		out.append({"key": enemy_key(n), "name": "👑 " + n, "desc": "Boss"})
	return out

# Codex ekranı için kategori listesi: her biri {title, entries:[{key,name,desc}]}.
static func categories() -> Array:
	return [
		{"title": "FORMLAR", "entries": forms()},
		{"title": "ARKETİPLER", "entries": archetypes()},
		{"title": "RELİKLER", "entries": relics()},
		{"title": "DÜŞMANLAR", "entries": enemies()},
	]

static func total_count() -> int:
	var n := 0
	for c in categories():
		n += (c["entries"] as Array).size()
	return n

# discovered listesinden kaç tanesi kodeks kataloğunda (geçersiz/eski anahtar sayılmaz).
static func discovered_count(discovered: Array) -> int:
	var n := 0
	for c in categories():
		for e in c["entries"]:
			if e["key"] in discovered:
				n += 1
	return n
