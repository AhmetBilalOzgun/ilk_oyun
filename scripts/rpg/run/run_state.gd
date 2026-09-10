extends RefCounted
class_name RunState

# Tek bir run'ın ÇALIŞMA ZAMANI durumu. Saf/headless. Parti loadout'ları (run-içi
# rün kiti + taşınan HP), biriken ödül, düğüm ilerlemesi. Run bitince atılır;
# kalıcı olan (para, açılan rünler) MetaProgress'e aktarılır (ayrı katman, sonra).

var loadouts: Dictionary = {}   # char_id -> RunLoadout
var party_order: Array = []     # char_id sırası (UI/sıra için)
var gold: int = 0
var node_index: int = 0

func _init(party: Array, base_runes: Dictionary = {}) -> void:
	# party: Array[Character]. base_runes: char_id -> Array[String] (bölüm başı kit).
	for c in party:
		var runes: Array = base_runes.get(c.id, [])
		loadouts[c.id] = RunLoadout.new(c, runes)
		party_order.append(c.id)

func loadout(char_id: String) -> RunLoadout:
	return loadouts.get(char_id, null)

func ordered_loadouts() -> Array:
	var out: Array = []
	for cid in party_order:
		out.append(loadouts[cid])
	return out
