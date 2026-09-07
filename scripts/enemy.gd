extends Node

# Yeniden kullanılabilir düşman davranışı. Bir gövdeyi (ColorRect) hedefe
# (Player) doğru yürütür ve menzile girince melee saldırır. Görsel/HP yok —
# Health bileşeni ayrı tutulur, bu node sadece hareket + saldırı mantığı.
#
# Tank profili: yüksek HP (dışarıda ENEMY_MAX_HP), DÜŞÜK hasar, DÜŞÜK hız.
# Öldürmesi zor ama tehlikesi yavaş birikir.
#
# Önceki bug: düşman menzil kontrolü olmadan vuruyordu (uzaktan da oyuncu HP
# yiyordu). Burada saldırı yalnızca kenar-kenar mesafe attack_range altına
# inince tetiklenir.

signal attacked(damage: int)   # hedefe her başarılı vuruşta yayılır

# --- Tank profili (dışarıdan override edilebilir) ---
@export var move_speed: float = 45.0       # px/sn — yavaş
@export var attack_damage: int = 5         # düşük hasar
@export var attack_cooldown: float = 1.4   # saldırılar arası bekleme (sn)
@export var attack_range: float = 24.0     # gövdeler arası yatay tetik mesafesi (px)

var body: ColorRect      # hareket eden düşman gövdesi
var target: ColorRect    # hedef (oyuncu gövdesi)
var target_health        # oyuncunun Health bileşeni
var self_health          # düşmanın kendi Health bileşeni

var _cd_left := 0.0

func setup(p_body: ColorRect, p_target: ColorRect, p_target_health, p_self_health) -> void:
	body = p_body
	target = p_target
	target_health = p_target_health
	self_health = p_self_health

# main._process içinden her frame çağrılır.
func tick(delta: float) -> void:
	if body == null or not is_instance_valid(body):
		return
	if self_health != null and not self_health.is_alive():
		return
	if target == null or not is_instance_valid(target):
		return
	if target_health != null and not target_health.is_alive():
		return

	if _gap_to_target() > attack_range:
		# Yürü: hedefe doğru yatay ilerle.
		var dir := signf(_target_center().x - _body_center().x)
		body.position.x += dir * move_speed * delta
		_cd_left = 0.0  # menzile girer girmez ilk vuruş anında olsun
	else:
		# Menzilde: cooldown ile saldır.
		_cd_left -= delta
		if _cd_left <= 0.0:
			_cd_left = attack_cooldown
			if target_health != null:
				target_health.take_damage(attack_damage)
				attacked.emit(attack_damage)

func _body_center() -> Vector2:
	return body.get_global_rect().get_center()

func _target_center() -> Vector2:
	return target.get_global_rect().get_center()

# Gövdeler arası yatay kenar mesafesi (üst üste binerse 0).
func _gap_to_target() -> float:
	var a := body.get_global_rect()
	var b := target.get_global_rect()
	var right_gap := b.position.x - (a.position.x + a.size.x)
	var left_gap := a.position.x - (b.position.x + b.size.x)
	return max(0.0, max(right_gap, left_gap))
