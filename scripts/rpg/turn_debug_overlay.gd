extends CanvasLayer
class_name TurnDebugOverlay

# Turn-based savaş debug overlay'i. Aktif sıra, durum ve son hasar dökümü (taban +
# bonus + zaaf/direnç AYRI AYRI) gösterir. Ayrıca sıra listesi + HP. F1 ile aç/kapa.
# Çizim KALDIRILDI; aktif girdi (tap/swipe) -> AWAITING_INPUT durumu.

var _label: Label

# TurnManager.State ile hizalı: IDLE, SELECTING_ACTION, AWAITING_INPUT, RESOLVING,
# NEXT_TURN, BATTLE_OVER.
const _STATE_NAMES := {
	0: "Idle", 1: "Beceri Seç", 2: "Girdi Bekle", 3: "Çözülüyor",
	4: "Sıra Geç", 5: "Savaş Bitti"
}

func _ready() -> void:
	layer = 100
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.55)
	panel.position = Vector2(16, 16)
	panel.size = Vector2(640, 420)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_label = Label.new()
	_label.position = Vector2(28, 26)
	_label.add_theme_font_size_override("font_size", 24)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		visible = not visible

func update_view(tm: TurnManager) -> void:
	if _label == null:
		return
	if tm == null:
		# Savaş arası (seçim/run sonu): aktif savaş yok.
		_label.text = "(savaş yok — seçim/run sonu)"
		return
	var active_txt := "-"
	if tm.active != null:
		active_txt = "%s (hız %d)" % [tm.active.display_name(), tm.active.speed()]

	var dmg_txt := "-"
	if tm.last_breakdown != null:
		var b: DamageBreakdown = tm.last_breakdown
		dmg_txt = "taban %d  +bonus x%.2f=%d  zaaf x%.2f  direnç x%.2f  => %d" % [
			b.base, b.bonus_multiplier, b.after_bonus,
			b.weakness_multiplier, b.resist_multiplier, b.final_damage]

	var lines := [
		"durum     : %s" % _STATE_NAMES.get(tm.state, "?"),
		"aktif sıra: %s" % active_txt,
		"son hasar : %s" % dmg_txt,
		"",
		"-- sıra listesi --",
	]
	for i in range(tm.order.size()):
		var c: Combatant = tm.order[i]
		var marker := ">" if c == tm.active else " "
		var side := "P" if c.side == Combatant.Side.PARTY else "E"
		var dead := " (öldü)" if not c.is_alive() else ""
		var extra := ""
		if c.side == Combatant.Side.PARTY:
			extra += " ⚡%d/%d" % [c.charge, c.charge_max]
		if c.stunned:
			extra += " STUN"
		if c.pending_dot > 0:
			extra += " DoT%d" % c.pending_dot
		lines.append("%s [%s] %-14s HP %d%s%s" % [marker, side, c.display_name(), c.hp, dead, extra])
	lines.append("")
	lines.append("(F1: overlay aç/kapa)")
	_label.text = "\n".join(lines)
