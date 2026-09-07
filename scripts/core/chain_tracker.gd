extends RefCounted
class_name ChainTracker

# Kombodan TAMAMEN bağımsız 2. sayaç: oyuncu hasar almadan geçen düşman ölümü.
# Kombonun kırılması zinciri etkilemez; zincirin kırılması komboyu etkilemez.
# Kırılma koşulu config'ten: "damage" (varsayılan) veya "screen_pass".

var count: int = 0
var _break_on: String = "damage"

func _init(db: RuneDB) -> void:
	_break_on = db.chain_break_on

func on_enemy_death() -> void:
	count += 1

# Büyücü hasar aldı. Varsayılan kırılma koşulu.
func on_player_damaged() -> void:
	if _break_on == "damage":
		count = 0

# Düşman ekranı geçti. Alternatif kırılma koşulu (config bayrağı).
func on_enemy_passed() -> void:
	if _break_on == "screen_pass":
		count = 0
