extends Resource
class_name MageForm

# Bir büyücünün KİMLİĞİ (veri). Rün eklemek yeni bir büyü değil — YENİ BİR KİMLİK
# demektir (bkz spec Part 5). Storm rünü alınınca Kor(Ember) -> Plazma'ya DÖNÜŞÜR:
# temel büyü, aktif girdi, pasif ve ultimate'in HEPSİ değişir. Eski form gider.
#
# Alanlar:
#   basic_spell    : temel büyü (Skill; kendi input_sequence'i var).
#   ultimate       : requires_charge=true büyü (enerji barı dolunca).
#   passive_hook   : kimlik pasifi etiketi (örn. "burn_on_hit"). MVP'de pasif
#                    çoğunlukla basic_spell verisiyle ifade edilir (Ember burn =
#                    basic_spell.dot_fraction); hook ileriye dönük + UI açıklaması.
#   passive_amount : pasif tuning değeri (örn. yakma oranı).
#   sprite_key     : sunumda hangi büyücü sprite seti kullanılır.
# Saf veri: Node/Engine bilmez. code_anchors durable key: MageForm.

@export var id: String = ""
@export var display_name: String = ""
@export var basic_spell: Skill = null
@export var ultimate: Skill = null
@export var passive_hook: String = ""
@export var passive_amount: float = 0.0
@export var passive_text: String = ""          # UI: pasifi bir cümlede anlat
@export var sprite_key: String = "wizard"
@export var element_effect: String = ""        # bu formun element etiketi (Burn vb.)

func _init(p_id := "", p_name := "") -> void:
	id = p_id
	display_name = p_name

# Bu formun savaşta kullanılabilir becerileri: temel + (varsa) ultimate.
func skills() -> Array[Skill]:
	var out: Array[Skill] = []
	if basic_spell != null:
		out.append(basic_spell)
	if ultimate != null:
		out.append(ultimate)
	return out
