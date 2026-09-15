extends RefCounted
class_name ChoiceOption

# Bir seçim düğümünde sunulan tek seçenek. Saf/headless. apply() RunState'e
# uygulanır. Çekirdek kanca: ACQUIRE_RUNE bir büyücünün formunu DÖNÜŞTÜRÜR (Ember +
# Storm -> Plazma). Hedef form generator tarafından önceden hesaplanıp params'a konur
# (apply'ın catalog'a ihtiyacı olmasın).
#
#   ACQUIRE_RUNE : params{char_id, rune_id, form} — büyücüyü yeni forma dönüştür.
#   HEAL         : params{char_id, amount}  — canını doldur (char_id "" -> tüm parti).
#   MAX_HP       : params{char_id, amount}  — max HP'yi kalıcı (run boyu) yükselt.
#   ARCHETYPE    : params{char_id, archetype} — build katmanı (Burn/Crit/Explosion)
#                  aktif forma bindirilir (kimlik-swap'ı değiştirmez, enhancement).

enum Kind { ACQUIRE_RUNE, HEAL, MAX_HP, RELIC, ARCHETYPE }

var kind: int
var label: String
var params: Dictionary
var cost: int = 0   # bu kartı seçmek için gereken DRAFT PUANI (fizik board'dan gelir)

func _init(p_kind: int, p_label: String, p_params: Dictionary = {}, p_cost: int = 0) -> void:
	kind = p_kind
	label = p_label
	params = p_params
	cost = p_cost

func apply(run_state: RunState) -> void:
	match kind:
		Kind.ACQUIRE_RUNE:
			var lo: RunLoadout = run_state.loadout(params["char_id"])
			if lo != null:
				lo.transform_to(params.get("form", null))
		Kind.HEAL:
			var amt: int = params.get("amount", 0)
			var cid: String = params.get("char_id", "")
			if cid == "":
				for l in run_state.loadouts.values():
					l.heal(amt)
			else:
				var l2: RunLoadout = run_state.loadout(cid)
				if l2 != null:
					l2.heal(amt)
		Kind.MAX_HP:
			var lo3: RunLoadout = run_state.loadout(params["char_id"])
			if lo3 != null:
				lo3.raise_max_hp(params.get("amount", 0))
		Kind.RELIC:
			var relic = params.get("relic", null)
			if relic != null:
				run_state.relics.append(relic)
		Kind.ARCHETYPE:
			var loa: RunLoadout = run_state.loadout(params.get("char_id", ""))
			if loa != null:
				loa.add_archetype(params.get("archetype", null))
