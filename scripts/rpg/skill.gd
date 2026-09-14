extends Resource
class_name Skill

# Tek bir beceri tanımı (veri). Bir MageForm'un TEMEL büyüsü ya da ULTIMATE'i, ya da
# bir düşman saldırısı. Çizim/QTE KALDIRILDI — her oyuncu becerisi bir input_sequence
# (kısa tap/swipe dizisi) taşır; sonucu (PERFECT/GOOD/MISS) hasar çarpanına çevrilir
# (bkz InputEvaluator + BattleConfig.input_multiplier). Çarpan DIŞARIDAN gelir ->
# Skill sabit bir "bonus" tutmaz.
#
# Alanlar:
#   rune_id  : element etiketi (görsel/renk + zaaf sistemi için canonical).
#   effect   : zaaf/direnç etiketi ("Burn"/"Freeze"/"Push"/"Shatter"; "" = etkisiz).
#   requires_charge : ULTIMATE — enerji (şarj) barı dolunca seçilebilir.
#   dot_fraction    : >0 -> hedef sonraki tur son hasarın bu oranını yakma olarak yer
#                     (Kor/Ember pasifi = temel büyüde küçük dot_fraction).
#   applies_stun    : hedef bir sonraki turunu atlar.
#   aoe             : tüm düşmanlara vurur (Inferno / Plasma Storm ultimate'leri).
# Saf veri: Node/Engine/zaman bilmez. code_anchors durable key: Skill.

@export var id: String = ""
@export var display_name: String = ""
@export var rune_id: String = ""               # element etiketi (görsel + zaaf)
@export var base_damage: int = 0               # garanti taban (çarpan input'tan gelir)
@export var carrier: String = "Projectile"     # görsel taşıyıcı string
@export var effect: String = ""                # zaaf/direnç için etki ("" = etkisiz)

@export var input_sequence: InputSequence = null  # oyuncu aktif girdisi (düşmanda null)
@export var requires_charge: bool = false      # true -> ULTIMATE, şarj barı dolu olmalı
@export var dot_fraction: float = 0.0          # >0: yakma DoT (form pasifi/ultimate)
@export var applies_stun: bool = false         # true: hedef bir tur atlar
@export var aoe: bool = false                  # true: tüm düşmanları vurur (ultimate)

func _init(p_id := "", p_name := "", p_rune := "", p_base := 0,
		p_carrier := "Projectile", p_effect := "") -> void:
	id = p_id
	display_name = p_name
	rune_id = p_rune
	base_damage = p_base
	carrier = p_carrier
	effect = p_effect
