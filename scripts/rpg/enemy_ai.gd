extends RefCounted
class_name EnemyAI

# Basit düşman karar fonksiyonu (STUB — kolayca değiştirilebilir).
# MVP kuralı: en düşük CANLI hedefe, en yüksek base_damage'lı beceriyi kullan.
# Boş dict döner -> yapılacak eylem yok (canlı hedef veya beceri yok).
# Saf/statik. Karmaşık davranış ağacı MVP dışı.

static func choose_action(actor: Combatant, targets: Array, _config: BattleConfig) -> Dictionary:
	var alive: Array = []
	for t in targets:
		if t.is_alive():
			alive.append(t)
	if alive.is_empty():
		return {}
	var skills: Array = actor.skills()
	if skills.is_empty():
		return {}

	var target: Combatant = alive[0]
	for t in alive:
		if t.hp < target.hp:
			target = t

	var best: Skill = skills[0]
	for s in skills:
		if s.base_damage > best.base_damage:
			best = s

	return {"skill": best, "target": target}
