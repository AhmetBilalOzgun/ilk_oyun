extends RefCounted
class_name RunManager

# Run (bölüm) omurgası. Düğüm listesini sırayla gezer; savaşı KENDİ SÜRMEZ
# (TurnManager gibi host-callback'li): BATTLE/BOSS'ta düşman setini dışarı verir,
# host savaşı TurnManager ile sürer ve sonucu report_battle_result(won) ile bildirir.
# CHOICE'ta seçenekleri üretir, host apply_choice(i) çağırır. REWARD terminal:
# parayı RunState'e yazar, RUN_WON. Herhangi bir savaş kaybı -> RUN_LOST.
#
# Saf/headless: Node/Engine/zaman bilmez. Desen: [BATTLE,CHOICE]×N -> BOSS -> REWARD
# (bkz StageDef). Seçenek üretimi deterministik (RunManager'ın rng'si).

enum State { IDLE, AWAITING_BATTLE, AWAITING_CHOICE, RUN_WON, RUN_LOST }

signal node_entered(node)          # RunNode
signal battle_requested(enemies)   # Array[Enemy] — host savaşı kursun
signal choice_requested(options)   # Array[ChoiceOption]
signal choice_applied(option)      # ChoiceOption
signal run_ended(won)              # bool

var catalog: SkillCatalog
var rng: RandomNumberGenerator

var state: int = State.IDLE
var nodes: Array = []
var run_state: RunState = null
var current_choices: Array = []

func _init(p_catalog: SkillCatalog = null, p_rng: RandomNumberGenerator = null) -> void:
	catalog = p_catalog if p_catalog != null else SkillCatalog.new()
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()

func start(p_nodes: Array, p_run_state: RunState) -> void:
	nodes = p_nodes
	run_state = p_run_state
	_enter(0)

func current_node() -> RunNode:
	if run_state == null or run_state.node_index >= nodes.size():
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
	_advance()

func apply_choice(index: int) -> void:
	if state != State.AWAITING_CHOICE:
		return
	if index < 0 or index >= current_choices.size():
		return
	var opt: ChoiceOption = current_choices[index]
	opt.apply(run_state)
	choice_applied.emit(opt)
	_advance()

# --- İçsel akış ---

func _advance() -> void:
	_enter(run_state.node_index + 1)

func _enter(index: int) -> void:
	if index >= nodes.size():
		_finish_won()
		return
	run_state.node_index = index
	var node: RunNode = nodes[index]
	node_entered.emit(node)

	match node.type:
		RunNode.Type.BATTLE, RunNode.Type.BOSS:
			state = State.AWAITING_BATTLE
			battle_requested.emit(node.enemies())
		RunNode.Type.CHOICE:
			current_choices = ChoiceGenerator.generate(run_state, catalog, rng)
			state = State.AWAITING_CHOICE
			choice_requested.emit(current_choices)
		RunNode.Type.REWARD:
			run_state.gold += int(node.data.get("gold", 0))
			_finish_won()

func _finish_won() -> void:
	state = State.RUN_WON
	run_ended.emit(true)
