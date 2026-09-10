extends Resource
class_name Skill

# Tek bir beceri tanımı (veri). Turn-based savaşta karakter/düşman bunu kullanır.
# İki tür beceri:
#   NORMAL   : tek rün QTE (rune_id). qte_bonus_multiplier başarıda hasar çarpanı.
#   BİRLEŞİM : requires_charge=true + rune_sequence (peş peşe çizilecek kaynak
#              rünler, ör. ["ember","storm"]). Şarj barı dolunca seçilebilir,
#              kullanınca bar sıfırlanır. Tüm dizi doğru çizilirse BÜYÜK buff
#              (yüksek qte_bonus_multiplier). Yeni şekil yok — mevcut rünler.
# Durum etkileri (birleşim kimliği): dot_fraction (yakma: sonraki tur hasarın
# %X'i tekrar) ve applies_stun (hedef bir tur atlar).
# Saf veri: Node/Engine/zaman bilmez. code_anchors durable key: Skill.

@export var id: String = ""
@export var display_name: String = ""
@export var rune_id: String = ""               # NORMAL beceri: QTE'de çizilecek rün
@export var base_damage: int = 0               # QTE'den bağımsız garanti taban
@export var qte_time_limit: float = 2.0        # sn, ölçeklenmemiş (birleşimde HER adım için)
@export var qte_bonus_multiplier: float = 1.5  # başarılı QTE'de hasar çarpanı
@export var carrier: String = "Projectile"     # RuneDB carrier string
@export var effect: String = ""                # zaaf/direnç için etki ("" = etkisiz)

# --- Birleşim (ultimate) alanları ---
@export var requires_charge: bool = false      # true -> şarj barı dolu değilse seçilemez
@export var rune_sequence: Array = []          # peş peşe çizilecek rün id'leri (boş -> [rune_id])
@export var dot_fraction: float = 0.0          # >0: hedef sonraki tur son hasarın bu oranını yer
@export var applies_stun: bool = false         # true: hedef bir sonraki turunu atlar

func _init(p_id := "", p_name := "", p_rune := "", p_base := 0,
		p_limit := 2.0, p_bonus := 1.5, p_carrier := "Projectile", p_effect := "") -> void:
	id = p_id
	display_name = p_name
	rune_id = p_rune
	base_damage = p_base
	qte_time_limit = p_limit
	qte_bonus_multiplier = p_bonus
	carrier = p_carrier
	effect = p_effect

# QTE'de çizilecek rün dizisi. Normal beceride tek elemanlı [rune_id].
func qte_runes() -> Array:
	return rune_sequence if not rune_sequence.is_empty() else [rune_id]
