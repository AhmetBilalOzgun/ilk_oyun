extends RefCounted
class_name RunManager

# Run (bölüm) omurgası. Düğüm GRAFINI (DAG) gezer; savaşı KENDİ SÜRMEZ (host-callback'li):
# BATTLE/ELITE/BOSS'ta düşman setini dışarı verir, host savaşı TurnManager ile sürer ve
# sonucu report_battle_result(won) ile bildirir. CHOICE'ta seçenekleri üretir. HEAL/TREASURE
# odaları anında çözülür. REWARD terminal.
#
# İLERLEME = graf kenarları (RunNode.next). Bir düğüm çözülünce sonrakiler bakılır:
#   0 sonraki  -> run biter (terminal) VEYA endless ise harita uzatılır (extend).
#   1 sonraki  -> otomatik ilerle (lineer akış — mevcut testler böyle çalışır).
#   >1 sonraki -> ROUTE seçimi (StS harita): route_requested emit, host choose(i) çağırır.
#
# Saf/headless: Node/Engine/zaman bilmez. Kaynak lineer Array (StageDef.linear) VEYA
# dallanmalı RunMap olabilir; ikisi de RunNode.next kenarlarını kullanır.

enum State { IDLE, AWAITING_BATTLE, AWAITING_CHOICE, AWAITING_ROUTE, RUN_WON, RUN_LOST }

signal node_entered(node)              # RunNode
signal battle_requested(enemies)       # Array[Enemy] — host savaşı kursun
signal choice_requested(options)       # Array[ChoiceOption]
signal choice_applied(option)          # ChoiceOption
signal route_requested(run_map, options)  # RunMap, Array[RunNode] — erişilebilir sonraki odalar
signal room_resolved(node)             # RunNode — HEAL/TREASURE gibi savaşsız oda çözüldü
signal transformed(form)               # MageForm — bir seçim büyücüyü dönüştürdü
signal run_ended(won)                  # bool

var catalog: SkillCatalog
var rng: RandomNumberGenerator

var state: int = State.IDLE
var nodes: Array = []          # düz RunNode listesi (indeksler = next kenarları)
var run_map: RunMap = null     # dallanmalı kaynak (endless extend için); lineer'de null
var run_state: RunState = null
var current_choices: Array = []
var route_options: Array = []  # AWAITING_ROUTE'ta erişilebilir düğümler (choose doğrular)

func _init(p_catalog: SkillCatalog = null, p_rng: RandomNumberGenerator = null) -> void:
	catalog = p_catalog if p_catalog != null else SkillCatalog.new()
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()

# source: RunMap (dallanmalı) VEYA Array[RunNode] (lineer, StageDef.linear).
func start(source, p_run_state: RunState) -> void:
	if source is RunMap:
		run_map = source
		nodes = run_map.nodes
	else:
		run_map = null
		nodes = source
	run_state = p_run_state
	_enter(0)

func current_node() -> RunNode:
	if run_state == null or run_state.node_index < 0 or run_state.node_index >= nodes.size():
		return null
	return nodes[run_state.node_index]

func current_enemies() -> Array:
	var n := current_node()
	return n.enemies() if n != null else []

# Host: aktif büyücü kiti. RunLoadout.available_skills ile beceri menüsü kurulur.
func party_loadouts() -> Array:
	return run_state.ordered_loadouts() if run_state != null else []

func report_battle_result(won: bool) -> void:
	if state != State.AWAITING_BATTLE:
		return
	if not won:
		state = State.RUN_LOST
		run_ended.emit(false)
		return
	# Zafer sayaçları (RunScore için): hangi tür savaş kazanıldı.
	var n := current_node()
	if n != null:
		match n.type:
			RunNode.Type.BOSS: run_state.bosses_won += 1
			RunNode.Type.ELITE: run_state.elites_won += 1
			_: run_state.battles_won += 1
	# Boss dahil her savaş sonrası CHOICE (orb board + kart) — graf CHOICE düğümüyle gelir.
	_advance()

# Kartları yeniden üret (reroll). Host puan bedelini kendi düşer.
func reroll_choices() -> void:
	if state != State.AWAITING_CHOICE:
		return
	current_choices = ChoiceGenerator.generate(run_state, catalog, rng)
	choice_requested.emit(current_choices)

# Kart uygulamadan CHOICE'u geç. Sıradaki düğüme ilerle.
func skip_choice() -> void:
	if state != State.AWAITING_CHOICE:
		return
	_advance()

func apply_choice(index: int) -> void:
	if state != State.AWAITING_CHOICE:
		return
	if index < 0 or index >= current_choices.size():
		return
	var opt: ChoiceOption = current_choices[index]
	var before := _form_ids()
	opt.apply(run_state)
	choice_applied.emit(opt)
	var after := _form_ids()
	for cid in after.keys():
		if before.get(cid, "") != after[cid]:
			transformed.emit(run_state.loadout(cid).current_form)
	_advance()

# ROUTE seçimi: erişilebilir bir sonraki düğümü seç (StS harita). node_index = seçilen indeks.
func choose(index: int) -> void:
	if state != State.AWAITING_ROUTE:
		return
	if index not in current_node().next:
		return   # erişilemez düğüm reddedilir (yalnız komşu sütun)
	_enter(index)

# --- İçsel akış ---

# Mevcut düğümün haleftlerine göre ilerle: 0 -> bitir/uzat, 1 -> otomatik, >1 -> route.
func _advance() -> void:
	var succ: Array = current_node().next
	if succ.is_empty():
		# Endless: harita sona erdi -> uzat, yeni kenarları oku. Değilse run biter.
		if run_state.endless and run_map != null:
			run_map.extend(rng, run_state.depth)
			nodes = run_map.nodes
			succ = current_node().next
		if succ.is_empty():
			_finish_won()
			return
	if succ.size() == 1:
		_enter(succ[0])
	else:
		route_options = []
		for i in succ:
			route_options.append(nodes[i])
		state = State.AWAITING_ROUTE
		route_requested.emit(run_map, route_options)

func _enter(index: int) -> void:
	if index < 0 or index >= nodes.size():
		_finish_won()
		return
	run_state.node_index = index
	var node: RunNode = nodes[index]
	node_entered.emit(node)

	match node.type:
		RunNode.Type.BATTLE, RunNode.Type.BOSS, RunNode.Type.ELITE:
			state = State.AWAITING_BATTLE
			battle_requested.emit(node.enemies())
		RunNode.Type.CHOICE:
			current_choices = ChoiceGenerator.generate(run_state, catalog, rng)
			state = State.AWAITING_CHOICE
			choice_requested.emit(current_choices)
		RunNode.Type.HEAL:
			var amt := int(node.data.get("amount", 25))
			for lo in run_state.loadouts.values():
				lo.heal(amt)
			room_resolved.emit(node)
			_advance()
		RunNode.Type.TREASURE:
			var relic = node.data.get("relic", null)
			if relic != null:
				run_state.relics.append(relic)
			run_state.orbs += int(node.data.get("orbs", 0))
			room_resolved.emit(node)
			_advance()
		RunNode.Type.REWARD:
			run_state.gold += int(node.data.get("gold", 0))
			_finish_won()

func _finish_won() -> void:
	state = State.RUN_WON
	run_ended.emit(true)

# char_id -> güncel form id (dönüşüm tespiti için).
func _form_ids() -> Dictionary:
	var out: Dictionary = {}
	for cid in run_state.party_order:
		var lo: RunLoadout = run_state.loadouts[cid]
		out[cid] = lo.current_form.id if lo.current_form != null else ""
	return out
