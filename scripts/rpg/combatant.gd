extends RefCounted
class_name Combatant

# Savaş sırasında bir katılımcının ÇALIŞMA ZAMANI durumu. Character VEYA Enemy
# kaynağını sarar, canlı HP + şarj barı + durum bayrakları tutar. Saf/headless.
# Parti üyelerinde weakness/resist yok -> boş dizi döner.
#
# Şarj barı: hasar VERİLDİĞİNDE ve ALINDIĞINDA dolar (miktar kadar). Dolunca
# (is_charged) birleşim becerisi seçilebilir; kullanınca sıfırlanır (consume_charge).
# Durum: stunned (bir sonraki tur atlanır), pending_dot (sonraki tur başında yenen
# gecikmiş hasar). İkisi de sıra başında TurnManager tarafından işlenir.

enum Side { PARTY, ENEMY }

var side: int                 # Side
var source                    # Character veya Enemy (Resource)
var hp: int

var charge: int = 0
var charge_max: int = 100
var stunned: bool = false
var pending_dot: int = 0

func _init(p_side: int, p_source, p_charge_max: int = 100) -> void:
	side = p_side
	source = p_source
	hp = p_source.max_hp
	charge_max = p_charge_max

func is_alive() -> bool:
	return hp > 0

func display_name() -> String:
	return source.display_name

func speed() -> int:
	return source.speed

func skills() -> Array:
	return source.skills

func weakness() -> Array:
	return source.weakness_effects if "weakness_effects" in source else []

func resist() -> Array:
	return source.resist_effects if "resist_effects" in source else []

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)

# --- Şarj barı ---

func gain_charge(amount: int) -> void:
	charge = clampi(charge + amount, 0, charge_max)

func is_charged() -> bool:
	return charge >= charge_max

func consume_charge() -> void:
	charge = 0
