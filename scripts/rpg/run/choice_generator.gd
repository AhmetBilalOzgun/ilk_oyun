extends RefCounted
class_name ChoiceGenerator

# Bir CHOICE düğümü için seçenekleri üretir. Saf/headless + DETERMİNİSTİK (verilen
# RandomNumberGenerator ile -> test edilebilir, seed'lenebilir). Rün draftı
# ağırlıklı: çoğu seçenek bir büyücüye yeni rün verir; bir yardımcı (heal/max HP)
# seçeneği eklenir. RNG yalnız BURADA (meta/seçim katmanı) — çizim anı saf beceri.

const DEFAULT_COUNT := 3

static func generate(run_state: RunState, catalog: SkillCatalog, rng: RandomNumberGenerator, count: int = DEFAULT_COUNT) -> Array:
	var drafts: Array = _draft_candidates(run_state, catalog)
	_shuffle(drafts, rng)

	var options: Array = []
	# Yardımcı seçenek için bir slot ayır (en az bir draft kalsın).
	var draft_slots: int = max(count - 1, 0) if drafts.size() >= count else drafts.size()
	for i in range(min(draft_slots, drafts.size())):
		options.append(drafts[i])

	# Kalan slotları yardımcılarla doldur.
	while options.size() < count:
		options.append(_utility(run_state, rng))

	return options

# Her büyücü × tutmadığı her rün -> bir DRAFT_RUNE adayı.
static func _draft_candidates(run_state: RunState, catalog: SkillCatalog) -> Array:
	var out: Array = []
	for cid in run_state.party_order:
		var lo: RunLoadout = run_state.loadouts[cid]
		for rune_id in catalog.rune_pool():
			if not lo.has_rune(rune_id):
				var label := "%s -> %s" % [lo.character.display_name, rune_id]
				out.append(ChoiceOption.new(ChoiceOption.Kind.DRAFT_RUNE, label,
					{"char_id": cid, "rune_id": rune_id}))
	return out

static func _utility(run_state: RunState, rng: RandomNumberGenerator) -> ChoiceOption:
	if rng.randi() % 2 == 0:
		return ChoiceOption.new(ChoiceOption.Kind.HEAL, "Partiyi iyileştir (+25)",
			{"char_id": "", "amount": 25})
	# Rastgele bir büyücüye +max HP.
	var cid: String = run_state.party_order[rng.randi() % run_state.party_order.size()]
	var name: String = run_state.loadouts[cid].character.display_name
	return ChoiceOption.new(ChoiceOption.Kind.MAX_HP, "%s +20 max can" % name,
		{"char_id": cid, "amount": 20})

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
