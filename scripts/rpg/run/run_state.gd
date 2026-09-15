extends RefCounted
class_name RunState

# Tek bir run'ın ÇALIŞMA ZAMANI durumu. Saf/headless. Parti loadout'ları (run-içi
# rün kiti + taşınan HP), biriken ödül, düğüm ilerlemesi. Run bitince atılır;
# kalıcı olan (para, açılan rünler) MetaProgress'e aktarılır (ayrı katman, sonra).

var loadouts: Dictionary = {}   # char_id -> RunLoadout
var party_order: Array = []     # char_id sırası (UI/sıra için)
var gold: int = 0
var orbs: int = 0               # yenilen düşman başına 1 (CHOICE'ta fizik board'a dökülür)
var relics: Array = []          # Array[Relic] — run boyu aktif kural kartları
var node_index: int = 0
var endless: bool = false           # endless mode: harita sonsuz uzar (boss yok), ritim
                                    # sürekli hızlanır (adaptive override; bkz battle.gd)
var depth: int = 0                  # temizlenen oda sayısı (endless zorluk + ritim ramp)
var allow_archetypes: bool = true   # build-bölüm cadence: false ise CHOICE arketip sunmaz
                                    # (bkz RunContent.is_build_level; host battle.gd kurar)
var unlocked_archetypes = null      # null => sınır yok (tüm arketipler). Array => yalnız bu
                                    # id'ler CHOICE'ta çıkabilir (battle-pass; Meta'dan kurulur)

func _init(party: Array, start_forms: Dictionary = {}) -> void:
	# party: Array[Character]. start_forms: char_id -> MageForm (başlangıç kimliği).
	for c in party:
		var form: MageForm = start_forms.get(c.id, null)
		loadouts[c.id] = RunLoadout.new(c, form)
		party_order.append(c.id)

func loadout(char_id: String) -> RunLoadout:
	return loadouts.get(char_id, null)

func ordered_loadouts() -> Array:
	var out: Array = []
	for cid in party_order:
		out.append(loadouts[cid])
	return out

# Aktif relic'lerden savaş motorunun sorgulayacağı RelicSet kur.
func relic_set() -> RelicSet:
	var rs := RelicSet.new()
	for r in relics:
		rs.add(r)
	# Build arketip efektleri: her loadout'un binen arketipleri de kanca taşır.
	for lo in loadouts.values():
		for e in lo.archetype_effects():
			rs.add(e)
	return rs
