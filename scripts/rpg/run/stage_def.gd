extends RefCounted
class_name StageDef

# Bir bölümün (run) LİNEER düğüm zincirini üretir. Saf/headless. Dallanma YOK — her
# düğüm tek haleften sonrakine bağlanır (RunManager otomatik ilerler). Dallanmalı StS
# haritası için bkz RunMap. Bu helper geriye dönük uyumluluk + basit testler içindir.
# Desen: [BATTLE, CHOICE] × N  ->  BOSS  ->  REWARD.
#
# linear():
#   battle_sets : Array[Array[Enemy]] — her eleman bir normal savaşın düşman seti.
#   boss_set    : Array[Enemy]        — boss savaşının düşmanları.
#   gold        : int                 — REWARD düğümünün verdiği para.
#   elite_set   : Array[Enemy]        — boştan farklıysa boss'tan ÖNCE bir ELITE
#                                       (risk/reward) savaşı + ardından CHOICE eklenir.

static func linear(battle_sets: Array, boss_set: Array, gold: int, elite_set: Array = []) -> Array:
	var nodes: Array = []
	for enemies in battle_sets:
		nodes.append(RunNode.new(RunNode.Type.BATTLE, {"enemies": enemies}))
		nodes.append(RunNode.new(RunNode.Type.CHOICE))
	if not elite_set.is_empty():
		nodes.append(RunNode.new(RunNode.Type.ELITE, {"enemies": elite_set}))
		nodes.append(RunNode.new(RunNode.Type.CHOICE))
	nodes.append(RunNode.new(RunNode.Type.BOSS, {"enemies": boss_set}))
	nodes.append(RunNode.new(RunNode.Type.REWARD, {"gold": gold}))
	return chain(nodes)

# Düğüm listesini tek-haleften zincire bağlar (next = [i+1]); son düğüm terminal (next=[]).
# col = indeks (UI için kaba yerleşim). Yerinde değiştirir + aynı diziyi döndürür.
static func chain(nodes: Array) -> Array:
	for i in range(nodes.size()):
		var n: RunNode = nodes[i]
		n.col = i
		n.row = 0
		var nx: Array[int] = []
		if i + 1 < nodes.size():
			nx.append(i + 1)
		n.next = nx
	return nodes
