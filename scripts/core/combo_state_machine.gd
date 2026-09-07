extends RefCounted
class_name ComboStateMachine

# Kombo durum makinesi. Saf/headless: motor zamanı OKUMAZ — dışarıdan
# ÖLÇEKLENMEMİŞ dt alır. Kritik: pencere/casting/overdrive süreleri
# Engine.time_scale'den bağımsız gerçek zamanla erir (gereksinim #1).
#
# Durumlar: Idle -> Casting -> ComboWindow -> (Casting | Idle)
# Overdrive dik (orthogonal) bir mod: aktifken çizimler biriktirilir, süre
# bitince TEK büyüye çözülür (ayrı kod yolu yok, aynı ComboResolver).
#
# Tanıma ADAPTÖRDE yapılır; buraya rune_id (veya null) verilir. null -> strike.

enum State { IDLE, CASTING, WINDOW }

const STRIKE := "strike"

var _db: RuneDB
var _ts: TimeScaleController

var state: int = State.IDLE
var depth: int = 0                 # atılmış rün sayısı (kombo derinliği)
var combo_runes: Array = []        # birikmiş kombo rünleri
var window_remaining: float = 0.0  # ölçeklenmemiş sn
var casting_remaining: float = 0.0 # casting üst sınırı (ölçeklenmemiş sn)
var current_time_scale: float = 1.0
var last_spell: ResolvedSpell = null

# Overdrive
var overdrive_active: bool = false
var overdrive_remaining: float = 0.0
var _overdrive_runes: Array = []
var _pending_overdrive_spell: ResolvedSpell = null

# Casting üst sınırı dolunca adaptörün çizimi zorla tamamlaması için bayrak.
var _force_commit := false

func _init(db: RuneDB, ts: TimeScaleController) -> void:
	_db = db
	_ts = ts
	_recompute_time_scale()

# --- Girdi olayları ---

# Parmak indi. Pencereyi dondurur (Casting'e geçer), casting sınırını başlatır.
func on_finger_down() -> void:
	if overdrive_active:
		# Overdrive sırasında da çizim yapılır; süre erimeye devam eder.
		return
	state = State.CASTING
	casting_remaining = _db.casting_cap_sec
	_recompute_time_scale()

# Parmak kalktı. rune_id: tanınan rün veya null (null/geçersiz -> strike).
# Tanınan rün: birikmiş komboyu tek büyüye çözer, döndürür, ComboWindow açar.
# STRIKE (düz vuruş / tık): STANDALONE — komboya EKLENMEZ, pencere AÇMAZ/uzatmaz,
#   depth artmaz (peş peşe tık hasarı büyütmez). Süren kombo korunur (bozmaz).
# Overdrive: rünü biriktirir, null döner (anlık büyü yok).
func on_finger_up(rune_id) -> ResolvedSpell:
	# STRIKE her zaman standalone: tık (null/geçersiz) VEYA çizilen düz çizgi (-> "strike").
	var recognized: bool = rune_id != null and _db.has_rune(rune_id) and rune_id != STRIKE

	if overdrive_active:
		_overdrive_runes.append(rune_id if recognized else STRIKE)
		return null

	if not recognized:
		# Düz vuruş: kombodan bağımsız sabit taban. Casting'ten çık, komboya dokunma.
		state = State.WINDOW if not combo_runes.is_empty() else State.IDLE
		_recompute_time_scale()
		return ComboResolver.resolve([STRIKE], _db)

	combo_runes.append(rune_id)
	depth = combo_runes.size()
	var spell := ComboResolver.resolve(combo_runes, _db)
	last_spell = spell
	state = State.WINDOW
	window_remaining = _db.window_for(depth)
	_recompute_time_scale()
	return spell

# Overdrive tetiği (çizimden AYRI girdi). Şarj dolu değilken adaptör hiç
# çağırmaz; yine de güvenli. Aktifken çift tetik yok sayılır.
func start_overdrive() -> void:
	if overdrive_active:
		return
	overdrive_active = true
	overdrive_remaining = _db.overdrive_duration_sec
	_overdrive_runes = []
	_pending_overdrive_spell = null
	_recompute_time_scale()

# --- Zaman ilerletme (ÖLÇEKLENMEMİŞ dt) ---

func tick(unscaled_dt: float) -> void:
	if overdrive_active:
		overdrive_remaining -= unscaled_dt
		if overdrive_remaining <= 0.0:
			_finish_overdrive()
		return

	if state == State.CASTING:
		# Parmak ekranda: pencere DONAR, casting sınırı sayılır (pause istismarı yok).
		casting_remaining -= unscaled_dt
		if casting_remaining <= 0.0:
			casting_remaining = 0.0
			_force_commit = true  # adaptör: çizimi zorla tamamla + on_finger_up
	elif state == State.WINDOW:
		# Parmak ekranda değil: pencere gerçek zamanla erir.
		window_remaining -= unscaled_dt
		if window_remaining <= 0.0:
			_reset_combo()
	_recompute_time_scale()

# --- Adaptör köprüleri ---

# Casting sınırı doldu mu? Adaptör okur, çizimi zorla tanır, on_finger_up çağırır.
func consume_force_commit() -> bool:
	if _force_commit:
		_force_commit = false
		return true
	return false

# Overdrive süresi bitince oluşan TEK birleşik büyü (varsa). Bir kez döner.
func consume_overdrive_spell() -> ResolvedSpell:
	var s := _pending_overdrive_spell
	_pending_overdrive_spell = null
	return s

# --- İç ---

func _finish_overdrive() -> void:
	overdrive_active = false
	overdrive_remaining = 0.0
	# Biriken tüm rünler TEK büyüye. Aynı resolver + overdrive hasar çarpanı.
	if not _overdrive_runes.is_empty():
		var spell := ComboResolver.resolve(_overdrive_runes, _db)
		spell.damage = int(round(spell.damage * _db.overdrive_damage_multiplier))
		spell.fusion_notes.append("OVERDRIVE x%.2f" % _db.overdrive_damage_multiplier)
		last_spell = spell
		_pending_overdrive_spell = spell
	_overdrive_runes = []
	# Overdrive komboyu bitirir → Idle, tam hız.
	_reset_combo()

func _reset_combo() -> void:
	state = State.IDLE
	depth = 0
	combo_runes = []
	window_remaining = 0.0
	casting_remaining = 0.0
	_recompute_time_scale()

func _recompute_time_scale() -> void:
	current_time_scale = _ts.compute(depth, overdrive_active)
