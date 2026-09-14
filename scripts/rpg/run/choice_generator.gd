extends RefCounted
class_name ChoiceGenerator

# Bir CHOICE düğümü için seçenekleri üretir. Saf/headless + DETERMİNİSTİK (verilen
# RandomNumberGenerator ile -> test edilebilir, seed'lenebilir). Dönüşüm ağırlıklı:
# uygun bir dönüşüm varsa rün-alma (transform) seçeneği sunulur; ayrıca relic + bir
# yardımcı (heal/max HP). RNG yalnız BURADA (meta/seçim katmanı).

const DEFAULT_COUNT := 3

# Kart türüne göre orb bedeli (fizik board'dan kazanılır). Relic en pahalı (kural
# değiştirir), dönüşüm orta, yardımcı en ucuz.
const COST := {
	ChoiceOption.Kind.ACQUIRE_RUNE: 20,
	ChoiceOption.Kind.HEAL: 10,
	ChoiceOption.Kind.MAX_HP: 12,
	ChoiceOption.Kind.RELIC: 30,
}

static func cost_for(kind: int) -> int:
	return COST.get(kind, 15)

static func generate(run_state: RunState, catalog: SkillCatalog, rng: RandomNumberGenerator, count: int = DEFAULT_COUNT) -> Array:
	# Havuz: uygun dönüşümler + henüz sahip olunmayan relic'ler.
	var pool: Array = _transform_candidates(run_state, catalog)
	pool.append_array(_relic_candidates(run_state, catalog))
	_shuffle(pool, rng)

	var options: Array = []
	# Yardımcı seçenek için bir slot ayır (en az bir kart havuzdan gelsin).
	var pool_slots: int = max(count - 1, 0) if pool.size() >= count else pool.size()
	for i in range(min(pool_slots, pool.size())):
		options.append(pool[i])

	# Kalan slotları yardımcılarla doldur.
	while options.size() < count:
		options.append(_utility(run_state, rng))

	return options

# Henüz sahip olunmayan her relic -> bir RELIC adayı.
static func _relic_candidates(run_state: RunState, catalog: SkillCatalog) -> Array:
	var owned := {}
	for r in run_state.relics:
		owned[r.id] = true
	var out: Array = []
	for relic in catalog.relics:
		if not owned.has(relic.id):
			out.append(ChoiceOption.new(ChoiceOption.Kind.RELIC,
				"%s — %s" % [relic.display_name, relic.description],
				{"relic": relic}, cost_for(ChoiceOption.Kind.RELIC)))
	return out

# Her büyücü × güncel formunu dönüştüren her rün -> bir ACQUIRE_RUNE adayı. Hedef
# form önceden hesaplanır ve params'a konur (apply catalog'suz çalışsın).
static func _transform_candidates(run_state: RunState, catalog: SkillCatalog) -> Array:
	var out: Array = []
	for cid in run_state.party_order:
		var lo: RunLoadout = run_state.loadouts[cid]
		if lo.current_form == null:
			continue
		for rune_id in catalog.acquirable_runes():
			var to_id := catalog.transform_for(lo.current_form.id, rune_id)
			if to_id == "":
				continue
			var to_form := catalog.form(to_id)
			if to_form == null:
				continue
			var label := "%s Rününü Al — %s ol" % [rune_id.capitalize(), to_form.display_name]
			out.append(ChoiceOption.new(ChoiceOption.Kind.ACQUIRE_RUNE, label,
				{"char_id": cid, "rune_id": rune_id, "form": to_form},
				cost_for(ChoiceOption.Kind.ACQUIRE_RUNE)))
	return out

static func _utility(run_state: RunState, rng: RandomNumberGenerator) -> ChoiceOption:
	if rng.randi() % 2 == 0:
		return ChoiceOption.new(ChoiceOption.Kind.HEAL, "Partiyi iyileştir (+25)",
			{"char_id": "", "amount": 25}, cost_for(ChoiceOption.Kind.HEAL))
	# Rastgele bir büyücüye +max HP.
	var cid: String = run_state.party_order[rng.randi() % run_state.party_order.size()]
	var name: String = run_state.loadouts[cid].character.display_name
	return ChoiceOption.new(ChoiceOption.Kind.MAX_HP, "%s +20 max can" % name,
		{"char_id": cid, "amount": 20}, cost_for(ChoiceOption.Kind.MAX_HP))

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
