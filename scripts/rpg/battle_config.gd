extends RefCounted
class_name BattleConfig

# Savaş tuning'i. Saf/headless. TurnManager'a verilir; verilmezse varsayılanlar.
# charge_max: birleşim (ultimate) becerisini açan şarj barı eşiği. Hasar
# verildikçe/alındıkça miktar kadar dolar (bkz Combatant.gain_charge).

var weakness_multiplier: float = 1.5    # zaaf etkisiyle vurunca ekstra
var resist_multiplier: float = 0.5      # direnç etkisiyle vurunca azaltma (asla 0)
var charge_max: int = 100               # birleşim becerisi bu eşikte açılır
