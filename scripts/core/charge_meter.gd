extends RefCounted
class_name ChargeMeter

# Overdrive şarj halkası. İSABETTEN dolar (öldürmeden değil): zorlanan oyuncunun
# ekranında daha çok düşman → daha çok isabet → yardım ihtiyaç anında gelir.
# Doluyken kazanılan şarj KAYBOLUR (taşma birikmez) — beklemenin bedeli.

var _hits_to_fill: int = 30
var hits: int = 0

func _init(db: RuneDB) -> void:
	_hits_to_fill = max(1, db.charge_hits_to_fill)

# İsabette çağrılır. Doluysa artık sayma (taşma yok).
func add_hit() -> void:
	if hits < _hits_to_fill:
		hits += 1

func is_full() -> bool:
	return hits >= _hits_to_fill

func ratio() -> float:
	return float(hits) / float(_hits_to_fill)

# Overdrive tetiklenince: yalnız doluysa tüketilir ve sıfırlanır.
# Dönüş: tetikleme başarılı mı (dolu değilse false — girdi yok sayılır).
func try_consume() -> bool:
	if not is_full():
		return false
	hits = 0
	return true
