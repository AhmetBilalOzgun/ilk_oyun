extends RefCounted
class_name ChoiceOption

# Bir seçim düğümünde sunulan tek seçenek. Saf/headless. apply() RunState'e
# uygulanır. Rün draftı oyunun çekirdek kancası: DRAFT_RUNE bir büyücüye rün
# ekler -> kaynak çifti tamamlanırsa birleşim otomatik açılır (bkz RunLoadout).
#
#   DRAFT_RUNE : params{char_id, rune_id} — büyücünün run kitine rün ekle.
#   HEAL       : params{char_id, amount}  — canını doldur (char_id "" -> tüm parti).
#   MAX_HP     : params{char_id, amount}  — max HP'yi kalıcı (run boyu) yükselt.

enum Kind { DRAFT_RUNE, HEAL, MAX_HP }

var kind: int
var label: String
var params: Dictionary

func _init(p_kind: int, p_label: String, p_params: Dictionary = {}) -> void:
	kind = p_kind
	label = p_label
	params = p_params

func apply(run_state: RunState) -> void:
	match kind:
		Kind.DRAFT_RUNE:
			var lo: RunLoadout = run_state.loadout(params["char_id"])
			if lo != null:
				lo.add_rune(params["rune_id"])
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
