extends RefCounted
class_name RunMap

# Dallanmalı run haritası (Slay-the-Spire tarzı sütun DAG'ı). Saf/headless VERİ KABI +
# wiring yardımcıları. İçerik (düşman/relic) RunContent tarafından doldurulur; RunMap
# yalnız yapıyı (düğümler, sütunlar, kenarlar) taşır. RunManager `nodes` + RunNode.next
# ile gezer (bkz RunManager). CHOICE düğümleri savaş sonrası ödül; haritada çizilmez.
#
# columns: harita çizimi (battle.gd) için sütun başına "oda" (BATTLE/ELITE/HEAL/TREASURE/
#          BOSS) düğüm indeksleri. CHOICE/REWARD gizli (columns'da yok).
# extender: endless için RunContent'in verdiği geri çağrı — func(map, rng, depth) sona
#           yeni sütun(lar) ekler ve last_rooms'tan wire eder. Campaign'de boş.

var nodes: Array = []          # Array[RunNode] (indeksler = next kenarları)
var columns: Array = []        # Array[Array[int]] — çizilen oda indeksleri (sütun başına)
var last_rooms: Array = []     # son sütunun oda indeksleri (extend wiring için)
var next_col: int = 0          # sıradaki sütun numarası (yerleşim + zorluk ölçeği)
var extender: Callable = Callable()

# Bir oda (çizilen) düğümü ekle. col/row çağıran tarafından atanır. İndeks döner.
func add_room(node: RunNode) -> int:
	var idx := nodes.size()
	nodes.append(node)
	return idx

# Gizli düğüm (CHOICE/REWARD) ekle — columns'a girmez. İndeks döner.
func add_hidden(node: RunNode) -> int:
	var idx := nodes.size()
	nodes.append(node)
	return idx

# Bir oda sütununu kaydet (indeksler) + last_rooms güncelle + next_col ilerlet.
func push_column(room_indices: Array) -> void:
	columns.append(room_indices.duplicate())
	last_rooms = room_indices.duplicate()
	next_col += 1

# SAVAŞ odasından sonraki odalara bağla: araya bir CHOICE (post-battle ödül) düğümü
# koyar (from -> CHOICE -> to_idx). Route (dallanma) CHOICE çıkışında tetiklenir.
func link_combat(from_idx: int, to_idx: Array) -> void:
	var ch := RunNode.new(RunNode.Type.CHOICE)
	var ci := add_hidden(ch)
	nodes[from_idx].next = _ti([ci])
	ch.next = _ti(to_idx)

# Savaşsız odadan (HEAL/TREASURE) doğrudan sonraki odalara bağla (CHOICE yok).
func link_direct(from_idx: int, to_idx: Array) -> void:
	nodes[from_idx].next = _ti(to_idx)

# Bir odayı türüne göre sonraki odalara bağla (combat -> CHOICE'lu, değilse doğrudan).
func link_room(from_idx: int, to_idx: Array) -> void:
	if nodes[from_idx].is_battle():
		link_combat(from_idx, to_idx)
	else:
		link_direct(from_idx, to_idx)

# Endless: haritayı uzat. extender geçerliyse çağırır (RunContent yeni sütun ekler).
func extend(rng: RandomNumberGenerator, depth: int) -> void:
	if extender.is_valid():
		extender.call(self, rng, depth)

func node_at(index: int) -> RunNode:
	return nodes[index] if index >= 0 and index < nodes.size() else null

static func _ti(src: Array) -> Array[int]:
	var out: Array[int] = []
	for v in src:
		out.append(int(v))
	return out
