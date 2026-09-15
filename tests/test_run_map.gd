extends RefCounted

# RunMap testleri: dallanmalı harita üretimi (campaign + endless). Deterministik (seed),
# yapı doğru (giriş -> orta sütun(lar) -> boss -> reward), kenarlar geçerli (her hedef
# erişilebilir), endless extend ile büyür. Saf/headless.

static func _rng(seed: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	return r

static func run(t) -> void:
	_test_campaign_structure(t)
	_test_deterministic(t)
	_test_edges_valid(t)
	_test_endless_extend(t)

# Campaign harita: en az giriş + orta + boss + reward; son oda BOSS; terminal REWARD.
static func _test_campaign_structure(t) -> void:
	t.section("map_campaign_structure")
	var m := RunContent.campaign_map(5, _rng(1))
	t.check(m.columns.size() >= 3, "en az 3 sütun (giriş+orta+boss)")
	t.check(m.columns[0].size() == 1, "giriş sütunu tek oda")
	var last_col: Array = m.columns[m.columns.size() - 1]
	t.check(last_col.size() == 1, "son sütun tek oda (boss)")
	var boss: RunNode = m.nodes[last_col[0]]
	t.check(boss.type == RunNode.Type.BOSS, "son oda BOSS")
	# Boss -> REWARD (terminal, next boş).
	var rewarded := false
	for ni in boss.next:
		if m.nodes[ni].type == RunNode.Type.REWARD and m.nodes[ni].next.is_empty():
			rewarded = true
	t.check(rewarded, "boss REWARD'a bağlı (terminal)")

# Aynı seed -> aynı yapı (düğüm sayısı + tür dizisi).
static func _test_deterministic(t) -> void:
	t.section("map_deterministic")
	var a := RunContent.campaign_map(6, _rng(9))
	var b := RunContent.campaign_map(6, _rng(9))
	t.check(a.nodes.size() == b.nodes.size(), "aynı seed -> aynı düğüm sayısı")
	var same := true
	for i in range(a.nodes.size()):
		if a.nodes[i].type != b.nodes[i].type:
			same = false
	t.check(same, "aynı seed -> aynı tür dizisi")

# Her oda düğümünün 'next'i geçerli indeks; her boss-öncesi oda ileri bağlı (ölü uç yok).
static func _test_edges_valid(t) -> void:
	t.section("map_edges_valid")
	var m := RunContent.campaign_map(7, _rng(3))
	var ok := true
	var dead := 0
	for i in range(m.nodes.size()):
		var n: RunNode = m.nodes[i]
		for ni in n.next:
			if ni < 0 or ni >= m.nodes.size():
				ok = false
		# REWARD terminal; diğer her düğümün en az bir haleften olmalı.
		if n.type != RunNode.Type.REWARD and n.next.is_empty():
			dead += 1
	t.check(ok, "tüm kenarlar geçerli indeks")
	t.check(dead == 0, "REWARD dışında ölü uç yok (got %d)" % dead)

# Endless: boss/reward yok; extend sona yeni sütun ekler (harita büyür).
static func _test_endless_extend(t) -> void:
	t.section("map_endless_extend")
	var rng := _rng(2)
	var m := RunContent.endless_map(rng)
	t.check(m.columns.size() >= 2, "endless başta >=2 sütun")
	var has_boss := false
	for n in m.nodes:
		if n.type == RunNode.Type.BOSS or n.type == RunNode.Type.REWARD:
			has_boss = true
	t.check(not has_boss, "endless: boss/reward YOK")
	var before := m.columns.size()
	m.extend(rng, 3)
	t.check(m.columns.size() > before, "extend sütun ekler (%d -> %d)" % [before, m.columns.size()])
	# extend sonrası: yalnız yeni frontier (last_rooms) boş next'li olmalı; gerisi bağlı.
	var still_dead := 0
	for i in range(m.nodes.size()):
		if m.nodes[i].is_room() and m.nodes[i].next.is_empty() and i not in m.last_rooms:
			still_dead += 1
	t.check(still_dead == 0, "extend eski uçları bağladı")
