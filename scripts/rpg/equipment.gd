extends Resource
class_name Equipment

# Kalıcı ekipman (meta katman). Relic ile AYNI hook desenini kullanır: bir hook
# etiketi + tuning değeri taşır, savaş motoru hook noktalarında sorar (RelicSet'e
# duck-typed eklenir — bkz Meta.equipped_list + battle.gd). 3 slot: HELMET/ARMOR/BOOTS.
# Düz stat yerine ilgi çekici etkiler (element hasarı, yansıtma, hız, şarj...).
#
# Combat hook'ları: burn_dmg_amp / shatter_dmg_amp (BattleDamage), reflect
# (TurnManager), charge_gain_mult (TurnManager, relic ile paylaşımlı). speed_flat /
# max_hp_flat savaş kurulumunda karaktere eklenir (battle.gd), hook değil.

enum Slot { HELMET, ARMOR, BOOTS }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var slot: int = Slot.HELMET
@export var hook: String = ""
@export var amount: float = 0.0
@export var cost: int = 0            # altın bedeli (meta shop)

func _init(p_id := "", p_name := "", p_slot := 0, p_hook := "", p_amount := 0.0,
		p_cost := 0, p_desc := "") -> void:
	id = p_id
	display_name = p_name
	slot = p_slot
	hook = p_hook
	amount = p_amount
	cost = p_cost
	description = p_desc

static func slot_name(s: int) -> String:
	match s:
		Slot.HELMET: return "Başlık"
		Slot.ARMOR: return "Zırh"
		Slot.BOOTS: return "Bot"
	return "?"

# MVP ekipman kataloğu — slot başına 3 parça (toplam 9).
static func catalog() -> Array:
	return [
		# --- Başlık ---
		Equipment.new("cond_helm", "İletken Başlık", Slot.HELMET, "shatter_dmg_amp", 1.35, 120,
			"Plazma (Shatter) hasarı +%35."),
		Equipment.new("focus_helm", "Odak Tacı", Slot.HELMET, "charge_gain_mult", 1.30, 140,
			"Şarj barı %30 daha hızlı dolar."),
		Equipment.new("vital_helm", "Diri Miğfer", Slot.HELMET, "max_hp_flat", 30.0, 100,
			"+30 max can."),
		# --- Zırh ---
		Equipment.new("flame_armor", "Alev Zırhı", Slot.ARMOR, "burn_dmg_amp", 1.40, 150,
			"Ateş (Burn) hasarı +%40."),
		Equipment.new("thorn_armor", "Diken Zırhı", Slot.ARMOR, "reflect", 0.15, 130,
			"Alınan hasarın %15'ini saldırgana yansıt."),
		Equipment.new("plate_armor", "Levha Zırh", Slot.ARMOR, "max_hp_flat", 60.0, 160,
			"+60 max can."),
		# --- Bot ---
		Equipment.new("swift_boots", "Tez Bot", Slot.BOOTS, "speed_flat", 6.0, 110,
			"+6 hız (daha erken sıra)."),
		Equipment.new("ember_boots", "Köz Çizme", Slot.BOOTS, "burn_dmg_amp", 1.20, 120,
			"Ateş (Burn) hasarı +%20."),
		Equipment.new("hardy_boots", "Sağlam Bot", Slot.BOOTS, "max_hp_flat", 40.0, 100,
			"+40 max can."),
	]

static func by_id(item_id: String) -> Equipment:
	for e in catalog():
		if e.id == item_id:
			return e
	return null
