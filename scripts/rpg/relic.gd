extends RefCounted
class_name Relic

# Kural-değiştiren kalıcı kart (run boyu). Saf/headless veri. Bir relic bir HOOK
# etiketi + tuning değeri taşır; savaş motoru (TurnManager / BattleDamage) hook
# noktalarında RelicSet'e sorar. Örnek hook'lar:
#   burn_spread     : yakma (DoT) komşu düşmanlara da yayılır. (amount kullanılmaz)
#   post_storm_amp  : Storm (Shatter) cast'inden sonra sonraki cast * amount.
#   frozen_amp      : sersem/donmuş hedefe hasar * amount.
# Yeni relic = yeni hook etiketi + (varsa) tuning; "+%10 hasar" gibi düz dolgu YOK.

var id: String
var display_name: String
var description: String
var hook: String
var amount: float

func _init(p_id := "", p_name := "", p_desc := "", p_hook := "", p_amount := 0.0) -> void:
	id = p_id
	display_name = p_name
	description = p_desc
	hook = p_hook
	amount = p_amount
