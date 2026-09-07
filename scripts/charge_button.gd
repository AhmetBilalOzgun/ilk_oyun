extends Control
class_name ChargeButton

# Overdrive şarj tuşu. Çizim karesinin sağında durur. Dolum alttan yukarı dolar
# (ne kadar kaldığı görünür). DOLUNCA parlar + basılabilir; dokununca overdrive
# tetiklenir. Dolu değilken dokunuş yok sayılır (girdi dinlenmez — spec kuralı).

signal triggered

const W := 150.0
const H := 150.0
const EMPTY_FILL := Color(0.55, 0.35, 0.85, 0.9)   # dolarken mor
const FULL_FILL := Color(0.95, 0.75, 0.25, 1.0)    # dolunca altın
const BG := Color(0.12, 0.12, 0.16, 0.95)
const BORDER := Color(0.35, 0.35, 0.42, 1)

var _charge: ChargeMeter
var _label: Label
var _pulse := 0.0

func setup(c: ChargeMeter) -> void:
	_charge = c

func _ready() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP   # dokunuşu yakalar (canvas'ı bloklamaz, ayrı bölge)
	_label = Label.new()
	_label.size = Vector2(W, H)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 30)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _process(dt: float) -> void:
	_pulse += dt
	queue_redraw()
	if _charge == null:
		return
	if _charge.is_full():
		_label.text = "BAS!"
	else:
		_label.text = "%d%%" % int(round(_charge.ratio() * 100.0))

func _draw() -> void:
	var r := _charge.ratio() if _charge != null else 0.0
	var full := _charge != null and _charge.is_full()
	# Arka plan
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	# Dolum: alttan yukarı
	var fh := size.y * clampf(r, 0.0, 1.0)
	var fill_col := FULL_FILL if full else EMPTY_FILL
	draw_rect(Rect2(Vector2(0, size.y - fh), Vector2(size.x, fh)), fill_col, true)
	# Kenarlık — dolunca nabız gibi parlar
	var bcol := BORDER
	var bw := 3.0
	if full:
		var a := 0.5 + 0.5 * sin(_pulse * 6.0)
		bcol = Color(1.0, 0.9, 0.4, 0.5 + 0.5 * a)
		bw = 6.0
	draw_rect(Rect2(Vector2.ZERO, size), bcol, false, bw)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Dolu değilken tetikleme girdisi dinlenmez.
		if _charge != null and _charge.is_full():
			triggered.emit()
			accept_event()
