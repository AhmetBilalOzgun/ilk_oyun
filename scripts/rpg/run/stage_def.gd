extends RefCounted
class_name StageDef

# Bir bölümün (run) düğüm listesini üretir. Saf/headless.
# Desen (senin istediğin): [BATTLE, CHOICE] × N  ->  BOSS  ->  REWARD.
# Yani her normal savaştan sonra bir seçim, son savaşlardan sonra boss, sonra ödül.
#
# linear():
#   battle_sets : Array[Array[Enemy]] — her eleman bir normal savaşın düşman seti.
#   boss_set    : Array[Enemy]        — boss savaşının düşmanları.
#   gold        : int                 — REWARD düğümünün verdiği para.

static func linear(battle_sets: Array, boss_set: Array, gold: int) -> Array:
	var nodes: Array = []
	for enemies in battle_sets:
		nodes.append(RunNode.new(RunNode.Type.BATTLE, {"enemies": enemies}))
		nodes.append(RunNode.new(RunNode.Type.CHOICE))
	nodes.append(RunNode.new(RunNode.Type.BOSS, {"enemies": boss_set}))
	nodes.append(RunNode.new(RunNode.Type.REWARD, {"gold": gold}))
	return nodes
