extends RefCounted
class_name RunScore

# Run PUANI: bir run'ın sonunda tek sayısal skor. Deterministik, saf/headless.
# Kaynak: ilerleme (endless kat / campaign düğüm) + toplanan build (relik + arketip)
# + öldürülen ELİT/BOSS + zafer bonusu + biriken altın. Meta.best_score ve günlük/
# haftalık meydan okuma tablosu (Challenge) bu skoru karşılaştırır. Formül tek yerde
# durur ki tüm tablolar tutarlı olsun. code_anchors durable key: RunScore.

const NODE := 10        # campaign: geçilen düğüm başına
const GOLD := 1         # biriken altın başına
const RELIC := 15       # toplanan relik başına
const ARCHETYPE := 25   # binen build arketipi başına
const ELITE := 40       # yenilen elit savaş başına
const BOSS := 100       # yenilen boss başına
const WIN := 150        # campaign run zaferi bonusu
const DEPTH := 12       # endless: temizlenen kat başına

static func compute(run_state: RunState, won: bool) -> int:
	if run_state == null:
		return 0
	var s := 0
	if run_state.endless:
		s += run_state.depth * DEPTH
	else:
		s += (run_state.node_index + 1) * NODE
		if won:
			s += WIN
	s += run_state.gold * GOLD
	s += run_state.relics.size() * RELIC
	var arch := 0
	for lo in run_state.loadouts.values():
		arch += lo.archetypes.size()
	s += arch * ARCHETYPE
	s += run_state.elites_won * ELITE
	s += run_state.bosses_won * BOSS
	return s
