extends Node2D

# Greybox can çubuğu: koyu arka plan + renkli dolum ColorRect'i.
# global_position = çubuğun sol-üst köşesi. Dolum HP oranına göre daralır ve
# yeşilden kırmızıya geçer. Fare girdisini engellemez (draw canvas'ı bloklamaz).

const WIDTH := 120.0
const HEIGHT := 14.0
const BG := Color(0.08, 0.08, 0.1, 0.9)
const HI := Color(0.35, 0.8, 0.4, 1)   # dolu
const LO := Color(0.85, 0.3, 0.25, 1)  # boşa yakın

var _bg: ColorRect
var _fill: ColorRect

func _ready() -> void:
	_bg = ColorRect.new()
	_bg.size = Vector2(WIDTH, HEIGHT)
	_bg.color = BG
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_fill = ColorRect.new()
	_fill.size = Vector2(WIDTH, HEIGHT)
	_fill.color = HI
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

func set_ratio(r: float) -> void:
	r = clampf(r, 0.0, 1.0)
	_fill.size = Vector2(WIDTH * r, HEIGHT)
	_fill.color = HI.lerp(LO, 1.0 - r)
