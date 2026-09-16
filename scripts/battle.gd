extends Node2D

# Run host sahnesi — RunManager omurgasını OYNANIR hale getirir.
# Akış: RunManager düğümleri gezer. BATTLE/BOSS'ta bu host bir TurnManager kurup
# savaşı sürer (QTE çizimi dahil); savaş bitince sonucu report_battle_result ile
# RunManager'a bildirir. CHOICE'ta seçim ekranı (rün draftı / boost) gösterir,
# tıklamada apply_choice çağırır. REWARD/bitiş -> run_ended ekranı.
#
# Yandan bakış düzeni: KARAKTERLER SOLDA, DÜŞMANLAR SAĞDA. Çizim KALDIRILDI; beceri
# seçilince AKTİF GİRDİ (tap/swipe dizisi) yakalanır -> PERFECT/GOOD/MISS -> hasar
# çarpanı (fail-soft). Beceriler güncel formdan gelir (RunLoadout.available_skills);
# Storm rünü alınınca form Plazma'ya DÖNÜŞÜR (menü + girdi + ultimate değişir).
# HP savaşlar arası taşınır (RunLoadout.current_hp); kazanınca düşenler %25 canla
# dirilir (MVP — run soft-lock olmasın). Tüm parti ölürse RUN_LOST.

# Run omurgası.
var rm: RunManager
var catalog: SkillCatalog
var run_state: RunState

# Aktif savaş (CHOICE sırasında null).
var tm: TurnManager = null

var overlay: TurnDebugOverlay

var skill_menu: VBoxContainer    # savaşta beceri menüsü / seçimde draft seçenekleri
var status_label: Label
var _bodies := {}   # Combatant -> {box, lbl, base_col}

var _last_usec := 0
var _next_turn_delay := 0.0
var _flash_label: Label       # geçici ekran-ortası flash (birleşim keşfi vb.)
var _flash_time := 0.0

# Savaş sonu ERTELEME: son vuruş anında (cast/ult + ölüm) animasyonları oynasın diye
# report_battle_result'ı hemen çağırmayız — birkaç saniye bekleriz (oyuncu ne olduğunu
# görsün), sonra finalize edip sıradaki node'u tetikleriz.
var _pending_end := false
var _pending_won := false
var _end_delay := 0.0
# Son seçilen beceri (action_selected'ta yakalanır) -> saldırı animasyonunu seçer
# (ultimate=requires_charge ise "ult", değilse "cast").
var _last_skill: Skill = null

# CHOICE'ta seçilen rün büyücüyü DÖNÜŞTÜRDÜYSE burada bekletilir; dönüşüm animasyonu
# CHOICE ekranında değil, BİR SONRAKİ savaşın ilk turunda (sprite varken) oynatılır.
var _pending_form_reveal: MageForm = null

# CHOICE: orb board + kart ekranı durumu.
var _board: OrbBoard = null
var _orbs := 0                    # board'dan kazanılan çarpılmış orb (kart bedeli)
var _pending_options: Array = []

# ROUTE: StS harita ekranı katmanı (çizgiler + oda butonları). Seçim yapılınca temizlenir.
var _map_layer: Node2D = null

# Büyü öncesi RİTİM KOMBO minigame'i (aktif). Beceri seçilince açılır; her tile bir
# "vuruş" (per-tile fireball + hasar sayısı), son tile FINISHER. Bittiğinde kombo skoru
# tek bir float çarpana indirgenip motora submit edilir. Eski kaydırma/basma jesti KALDIRILDI.
var _rhythm: RhythmMinigame = null
var _combo_target: Combatant = null   # kombonun hedefi (per-tile FX + submit)
var _combo_skill: Skill = null        # kombo becerisi (carrier/rune/pose)
var _combo_pf := 0.0                  # "hepsi-PERFECT" nihai hasar (per-tile sayı payı)
var _suppress_aggregate_fx := false   # kombo action'ında damage_resolved aggregate FX'i bastır

var _background: Sprite2D
var _world_index := 0
const WIZARD_SCENE := preload("res://scenes/wizard.tscn")

# Düşman sprite'ları (temiz atlas'a çevrilmiş referans). 3 set: dragon/goblin/dev.
const ENEMY_FRAMES := {
	"dragon": preload("res://assets/enemies/dragon_frames.tres"),
	"goblin": preload("res://assets/enemies/goblin_frames.tres"),
	"dev": preload("res://assets/enemies/dev_frames.tres"),
}
# Oyuncu büyücü sprite setleri — form kimliğine (sprite_key) göre seçilir.
# Ember(Kor)=wizard_fire, Plazma=wizard_arcane. Form dönüşünce sprite komple değişir.
# Büyü efekt sprite'ları (SpellFX). carrier + rune_id ile seçilir.
const FX_FIREBALL := preload("res://assets/wizard/fx_fireball.png")
const FX_PLASMA_ORB := preload("res://assets/wizard/fx_plasma_orb.png")
const FX_COMET := preload("res://assets/wizard/fx_fire_comet.png")
const FX_BEAM := preload("res://assets/wizard/fx_plasma_beam.png")
const FX_STORM := preload("res://assets/wizard/fx_storm.png")
const ENEMY_SCALE := 2.15          # 96px hücre -> ~206px (daha büyük çizim)
const ENEMY_COL_GAP := 155.0       # düşmanlar sağda yatay dizi (arka arkaya) aralığı
const ENEMY_FLOAT_LIFT := 100.0    # uçan türler hafif havada süzülür

const WIZARD_SCALE := 0.9          # 256px frame -> ~230px yükseklik (daha büyük)
const GROUND_Y := 1285.0           # zemin (tuğla duvar üstü) ayak çizgisi
const BODY_GAP := 210.0            # ek üyeler bu kadar yukarı istiflenir
const BAR_W := 140.0               # stat barı genişliği
const BAR_H := 16.0                # stat barı yüksekliği
const BAR_PAD := 2.0               # bar iç dolgu kenarı
const HOME = "res://scenes/home.tscn"
const NEXT_TURN_PAUSE := 0.8
const BATTLE_END_PAUSE := 1.6
const COMBO_BASE_LEN := 2       # kombo başlangıç tile sayısı (run başı)
const COMBO_MAX_LEN := 6        # kombo tavan tile sayısı (run ilerledikçe)
const PIXEL_FONT = preload("res://assets/fonts/PixelifySans-Bold.ttf")   # savaş bitince: ölüm/zafer/ult anim'i oynasın diye bekle
const REVIVE_FRACTION := 0.25   # kazanınca düşen parti üyesi bu oranda dirilir
const REROLL_COST := 15         # CHOICE kart reroll'unun draft puanı bedeli
const HEAL_FIXED_COST := 10     # CHOICE'ta sol "CAN AL" butonu orb bedeli
const HEAL_FIXED_AMOUNT := 25   # sol "CAN AL" butonu tüm partiyi bu kadar iyileştirir
const WAVE_CHARGE_DECAY := 0.20 # savaşlar (wave) arası taşınan şarjın kaybı (%20)
const ELITE_ORB_MULT := 2       # ELITE savaş orb ödülü çarpanı (risk/reward)
const RHYTHM_SPEEDUP_PER_WAVE := 0.12 # her tur (wave) geçtikçe ritim hızına eklenen çarpan
const ENDLESS_RHYTHM_RAMP := 0.06     # endless: her temizlenen oda ritim hız tabanına eklenir
const ENDLESS_GOLD_BASE := 10         # endless: oda başı temel altın (derinlikle artar)

const EFFECT_COLOR := {
	"Burn": Color(0.95, 0.45, 0.2, 1),
	"Freeze": Color(0.4, 0.75, 0.98, 1),
	"Push": Color(0.4, 0.85, 0.5, 1),
	"Shatter": Color(0.97, 0.87, 0.25, 1),
	"Steam": Color(0.88, 0.88, 0.92, 1),
}
const C_NEUTRAL := Color(0.85, 0.85, 0.9, 1)

func _ground_y() -> float:
	return maxf(1920.0, get_viewport_rect().size.y) * float(GameLook.GROUND_RATIOS[_world_index])

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("b9dce7"))
	_world_index = GameLook.world_index(Meta.selected_level)
	_background = Sprite2D.new()
	_background.centered = false
	_background.z_index = -10
	add_child(_background)
	_update_world()

	# Run omurgasını kur. Meta CAN upgrade'i parti max HP'sine baklanır (run
	# current_hp de buradan dolar). HASAR upgrade'i savaş başında becerilere eklenir.
	catalog = RunContent.catalog()
	# İlk 3 bölüm TEK karakterle: seçili büyücüden bir kişilik parti kur.
	var cid: String = Meta.selected_character
	var party := RunContent.single_party(cid)
	for c in party:
		# Meta CAN upgrade + ekipman max_hp bonusu; ekipman hız bonusu tur sırasına.
		c.max_hp += Meta.hp_bonus(c.id) + Meta.equipped_hp_bonus()
		c.speed += Meta.equipped_speed_bonus()
	run_state = RunState.new(party, RunContent.start_forms(catalog))
	run_state.endless = Meta.endless_run
	# Build cadence: arketip teklifi yalnız build-bölümlerinde; endless'ta hep açık.
	run_state.allow_archetypes = true if run_state.endless else RunContent.is_build_level(Meta.selected_level)
	# Battle-pass: yalnız mastery ile AÇILMIŞ arketipler CHOICE havuzunda çıkabilir.
	run_state.unlocked_archetypes = Meta.unlocked_archetypes.duplicate()
	var map_rng := RandomNumberGenerator.new()
	map_rng.randomize()
	rm = RunManager.new(catalog, map_rng)
	rm.battle_requested.connect(_on_battle_requested)
	rm.choice_requested.connect(_on_choice_requested)
	rm.route_requested.connect(_on_route_requested)
	rm.room_resolved.connect(_on_room_resolved)
	rm.transformed.connect(_on_transformed)
	rm.run_ended.connect(_on_run_ended)

	# Ortak UI.
	skill_menu = VBoxContainer.new()
	skill_menu.position = Vector2(90, _ground_y() + 110.0)
	skill_menu.add_theme_constant_override("separation", 10)
	add_child(skill_menu)

	status_label = Label.new()
	status_label.position = Vector2(40, 160)
	status_label.size = Vector2(1000, 50)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_override("font", PIXEL_FONT)
	status_label.add_theme_font_size_override("font_size", 32)
	status_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	status_label.add_theme_constant_override("outline_size", 6)
	status_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1.0))
	add_child(status_label)

	# Ekran ortasında büyük geçici flash (birleşim keşfi vb.). Başta gizli.
	_flash_label = Label.new()
	_flash_label.position = Vector2(40, 245)
	_flash_label.size = Vector2(1000, 60)
	_flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash_label.add_theme_font_override("font", PIXEL_FONT)
	_flash_label.add_theme_font_size_override("font_size", 40)
	_flash_label.add_theme_constant_override("outline_size", 8)
	_flash_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.1, 1))
	_flash_label.visible = false
	add_child(_flash_label)

	overlay = TurnDebugOverlay.new()
	overlay.visible = false
	add_child(overlay)

	_last_usec = Time.get_ticks_usec()
	var run_map: RunMap = RunContent.endless_map(map_rng) if run_state.endless \
		else RunContent.campaign_map(Meta.selected_level, map_rng)
	rm.start(run_map, run_state)

func _update_world() -> void:
	_background.texture = GameLook.backdrop(_world_index)
	_background.scale = Vector2(get_viewport_rect().size.x / _background.texture.get_width(), maxf(1920, get_viewport_rect().size.y) / _background.texture.get_height())

func _style_button(btn: Button, accent_color: Color = GameLook.TEAL, height: float = 78.0, width: float = 900.0, font_size: int = 30) -> void:
	btn.custom_minimum_size = Vector2(width, height)
	GameLook.button(btn, accent_color, font_size)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _on_battle_requested(enemies: Array) -> void:
	_clear_menu()
	_clear_bodies()
	_start_battle(enemies)

# CHOICE düğümü: önce ORB BOARD (kazanılan orb'lar -> draft puanı), sonra kart
# ekranı (puanla kart seç/reroll). Orb yoksa board atlanır, puan 0.
func _on_choice_requested(options: Array) -> void:
	tm = null
	_clear_bodies()
	_clear_menu()
	_pending_options = options
	# İlk giriş: orb varsa board aç. Reroll'da orb 0 -> doğrudan kart ekranı.
	if run_state.orbs > 0 and _board == null:
		_show_board()
	else:
		_show_cards()

func _show_board() -> void:
	status_label.text = "🎰 ORB BOARD — %d orb'unu dök" % run_state.orbs
	_board = OrbBoard.new()
	_board.finished.connect(_on_board_finished)
	add_child(_board)
	_board.setup(run_state.orbs, Rect2(90, 640, 900, 1140))
	run_state.orbs = 0   # board'a döküldü

func _on_board_finished(points: int) -> void:
	_orbs = points
	if _board != null:
		_board.queue_free()
		_board = null
	_flash("+%d ORB" % points, Color(0.5, 0.9, 1.0))
	_show_cards()

func _show_cards() -> void:
	_clear_menu()
	# CHOICE ekranı: TEK SATIR — sol CAN AL (kırmızı +), ortada 3 kutu yan yana, sağ PAS.
	skill_menu.position = Vector2(90, 700)
	skill_menu.add_theme_constant_override("separation", 22)
	status_label.text = "SEÇİM — %d orb  (%s)" % [_orbs, _progress_text()]

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	skill_menu.add_child(row)

	# SOL: CAN AL — büyük kırmızı +, orb bedeli. Yetmezse pasif.
	var heal := Button.new()
	var can_heal := _orbs >= HEAL_FIXED_COST
	heal.text = "+\n\nCAN AL\n[%d orb]" % HEAL_FIXED_COST
	heal.disabled = not can_heal
	_style_button(heal, Color(0.95, 0.28, 0.28), 380.0, 150.0, 34)
	heal.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42))
	heal.pressed.connect(_on_heal_fixed)
	row.add_child(heal)

	# ORTA: 3 seçenek kutusu yan yana (ikon üstte, ad ortada, bedel altta).
	for i in range(_pending_options.size()):
		var opt: ChoiceOption = _pending_options[i]
		var afford := _orbs >= opt.cost
		var card := Button.new()
		card.text = "%s\n\n%s\n\n[%d orb]%s" % [_choice_icon(opt), opt.label, opt.cost,
			"" if afford else "\n(yetersiz)"]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.disabled = not afford
		var accent := _choice_color(opt) if afford else Color(0.4, 0.4, 0.45)
		_style_button(card, accent, 380.0, 196.0, 26)
		card.pressed.connect(_on_choice_chosen.bind(i))
		# Build arketip kartı: üstünde "ARCHETYPE" rozet kutusu — belirgin dursun.
		if opt.kind == ChoiceOption.Kind.ARCHETYPE:
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", 6)
			col.add_child(_archetype_badge(accent))
			col.add_child(card)
			row.add_child(col)
		else:
			row.add_child(card)
		# Dönüşüm + build arketip kartı: parıltı ile dikkat çek (öne çıkan kararlar).
		if afford and (opt.kind == ChoiceOption.Kind.ACQUIRE_RUNE or opt.kind == ChoiceOption.Kind.ARCHETYPE):
			_pulse_button(card)

	# SAĞ: PAS — şekil (»») + etiket.
	var skip := Button.new()
	skip.text = "»»\n\nPAS"
	_style_button(skip, Color(0.6, 0.65, 0.75), 380.0, 150.0, 34)
	skip.pressed.connect(_on_skip)
	row.add_child(skip)

	# Alt: reroll (ikincil) — yeni kart seti.
	var re := Button.new()
	re.text = "🔄 REROLL  [%d orb]" % REROLL_COST
	re.disabled = _orbs < REROLL_COST
	_style_button(re, Color(0.95, 0.7, 0.25), 78.0, 900.0, 28)
	re.pressed.connect(_on_reroll)
	skill_menu.add_child(re)

# Seçenek türüne göre çerçeve rengi (mor=dönüşüm, altın=buff, yeşil=iyileş, turuncu=can).
func _choice_color(opt: ChoiceOption) -> Color:
	match opt.kind:
		ChoiceOption.Kind.ACQUIRE_RUNE: return Color(0.7, 0.4, 1.0)
		ChoiceOption.Kind.ARCHETYPE: return Color(1.0, 0.35, 0.22)
		ChoiceOption.Kind.RELIC: return Color(0.95, 0.75, 0.3)
		ChoiceOption.Kind.HEAL: return Color(0.4, 0.85, 0.5)
		ChoiceOption.Kind.MAX_HP: return Color(1.0, 0.55, 0.3)
	return Color(0.35, 0.75, 1.0)

# Arketip kartının üstündeki "ARCHETYPE" rozet kutusu (kart genişliğine yayılır).
func _archetype_badge(accent: Color) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent
	sb.set_corner_radius_all(10)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = "◈ ARCHETYPE ◈"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", PIXEL_FONT)
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(0.1, 0.06, 0.05))
	pc.add_child(l)
	return pc

# Mor parıltı nabzı (dönüşüm kartı öne çıksın).
func _pulse_button(btn: Control) -> void:
	var tw := create_tween().bind_node(btn).set_loops()
	tw.tween_property(btn, "modulate", Color(1.4, 1.1, 1.55, 1.0), 0.65).set_trans(Tween.TRANS_SINE)
	tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.65).set_trans(Tween.TRANS_SINE)

func _on_reroll() -> void:
	if _orbs < REROLL_COST:
		return
	_orbs -= REROLL_COST
	_clear_menu()
	rm.reroll_choices()   # -> choice_requested -> _on_choice_requested (orb 0 -> _show_cards)

func _on_skip() -> void:
	_clear_menu()
	rm.skip_choice()      # -> sıradaki düğüm, kart uygulamadan

# Sol CAN AL butonu: orb bedeliyle tüm partiyi iyileştir, sonra düğümü geç.
func _on_heal_fixed() -> void:
	if _orbs < HEAL_FIXED_COST:
		return
	_orbs -= HEAL_FIXED_COST
	for l in run_state.loadouts.values():
		l.heal(HEAL_FIXED_AMOUNT)
	_flash("+%d CAN" % HEAL_FIXED_AMOUNT, Color(1.0, 0.42, 0.42))
	_clear_menu()
	rm.skip_choice()      # iyileştir + düğümü geç (kart uygulamadan)

# Seçenek kutusunun üst ikonu (etiketten ayrı; kutu içinde büyük gösterilir).
func _choice_icon(opt: ChoiceOption) -> String:
	match opt.kind:
		ChoiceOption.Kind.ACQUIRE_RUNE: return "🔮"
		ChoiceOption.Kind.ARCHETYPE:
			var a = opt.params.get("archetype", null)
			return a.icon if a != null else "🔥"
		ChoiceOption.Kind.HEAL: return "❤"
		ChoiceOption.Kind.MAX_HP: return "➕"
		ChoiceOption.Kind.RELIC: return "🎁"
	return "⭐"

func _on_choice_chosen(index: int) -> void:
	_clear_menu()
	rm.apply_choice(index)   # -> sıradaki düğüm (battle_requested / run_ended)

# Bir seçim büyücüyü dönüştürdü. CHOICE ekranında sprite YOK — dönüşümü hemen
# göstermek yerine beklet; sonraki savaşın ilk turunda _reveal_transform oynatır.
func _on_transformed(form: MageForm) -> void:
	_pending_form_reveal = form

# Bekleyen dönüşümü göster: yeni forma geçen party sprite'ında "levelup" (yoksa
# "victory") reveal animasyonu + flash. Savaş kurulunca (sprite hazırken) çağrılır.
func _reveal_transform() -> void:
	if _pending_form_reveal == null:
		return
	var form := _pending_form_reveal
	_pending_form_reveal = null
	_flash("✨ YENİ FORM: %s" % form.display_name, Color(1.0, 0.85, 0.25), 2.6)
	for c in _bodies:
		var b: Dictionary = _bodies[c]
		if b.get("is_party", false):
			var spr: AnimatedSprite2D = b["sprite"]
			spr.sprite_frames = _player_frames(c)
			var reveal := "levelup" if spr.sprite_frames.has_animation("levelup") else "victory"
			if spr.sprite_frames.has_animation(reveal):
				spr.play(reveal)
			else:
				spr.play("idle")

# Party combatant'ının güncel formuna göre sprite setini seç (fail-soft: fire).
func _player_frames(c: Combatant) -> SpriteFrames:
	var lo := run_state.loadout(c.source.id)
	return GameLook.frames(GameLook.form_key(lo) if lo != null else "fire")

func _party_tint(_c: Combatant) -> Color:
	return Color.WHITE  # Each form now has its own authored palette and animation atlas.

# Ekran-ortası geçici yazı (birkaç saniye). _process söndürür.
func _flash(msg: String, col: Color, secs := 2.2) -> void:
	_flash_label.text = msg
	_flash_label.add_theme_color_override("font_color", col)
	_flash_label.visible = true
	_flash_time = secs

func _on_run_ended(won: bool) -> void:
	tm = null
	_clear_menu()
	_clear_bodies()
	_clear_map()
	var lvl: int = Meta.selected_level
	var cry := 0
	if run_state.endless:
		# Endless: kazanç ölümde bile BANKA edilir (fail-soft — ilerleme boşa gitmez).
		Meta.add_gold(run_state.gold)
		if run_state.depth > Meta.endless_best_depth:
			Meta.endless_best_depth = run_state.depth
			Meta.save_game()
	elif won:
		# Ödülü Meta'ya yaz + seviyeyi aç (sonraki kilidi açılır).
		cry = RunContent.reward_crystal(lvl)
		Meta.add_gold(run_state.gold)
		Meta.add_crystal(cry)
		Meta.clear_level(lvl)
	# RUN-END SUMMARY: run kapanış katmanı (savaş sonu değil). Kurulan build + ödül.
	_show_run_summary(won, cry)

# Run sonu özet paneli: başlık + kurulan build (form + arketip + relik) + ödül + eve.
func _show_run_summary(won: bool, cry: int) -> void:
	if run_state.endless:
		status_label.text = "♾ %d KAT İLERLEDİN" % run_state.depth
		status_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	else:
		status_label.text = "🏆 RUN TAMAMLANDI" if won else "💀 RUN BİTTİ"
		status_label.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.35) if won else Color(1.0, 0.5, 0.5))

	skill_menu.position = Vector2(90, 620)
	skill_menu.add_theme_constant_override("separation", 16)

	# BUILD başlığı + her büyücünün kimliği ("Alev Kor Büyücü") + binen arketipler.
	_summary_label("⚔  BUILD", 34, Color(0.7, 0.85, 1.0))
	for lo in run_state.ordered_loadouts():
		_summary_label("🔥 %s" % lo.form_display_name(), 30, Color(1.0, 0.6, 0.35))
		var arch: Array = []
		for a in lo.archetypes:
			arch.append(a.display_name)
		if not arch.is_empty():
			_summary_label("   %s" % ", ".join(arch), 24, Color(0.9, 0.75, 0.5))

	# Toplanan relikler (run boyu kural kartları).
	var relic_names: Array = []
	for r in run_state.relics:
		relic_names.append(r.display_name)
	if not relic_names.is_empty():
		_summary_label("🎁  %s" % ", ".join(relic_names), 24, Color(0.95, 0.8, 0.4))

	# Kazanılan değer.
	if run_state.endless:
		_summary_label("KAZANILAN:  +%d💰   (en iyi: %d kat)" % [run_state.gold, Meta.endless_best_depth],
			30, Color(0.5, 0.9, 0.6))
	elif won:
		_summary_label("KAZANILAN:  +%d💰   +%d💎" % [run_state.gold, cry], 30, Color(0.5, 0.9, 0.6))
	else:
		_summary_label("Buraya kadar: %s" % _progress_text(), 26, Color(0.8, 0.8, 0.85))

	# Ana ekrana dönüş.
	var home_btn := Button.new()
	home_btn.text = "🏠 ANA EKRAN"
	_style_button(home_btn, Color(0.35, 0.85, 0.45), 90.0)
	home_btn.pressed.connect(func(): get_tree().change_scene_to_file(HOME))
	skill_menu.add_child(home_btn)

# Özet paneline tek satır ekle (pixel font + kontur).
func _summary_label(text: String, size: int, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", PIXEL_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1.0))
	skill_menu.add_child(l)

func _progress_text() -> String:
	if run_state.endless:
		return "kat %d" % run_state.depth
	return "düğüm %d/%d" % [run_state.node_index + 1, rm.nodes.size()]

# =========================================================================
#  ROUTE — StS harita ekranı (dallanmalı ilerleme)
# =========================================================================

const MAP_TOP := 360.0            # harita üst kenarı (en ileri sütun)
const MAP_BOTTOM := 1560.0        # harita alt kenarı (mevcut/geçilen sütun)
const MAP_X0 := 140.0
const MAP_X1 := 940.0
const MAP_WINDOW := 5             # aynı anda gösterilen sütun sayısı (endless pencere)
const MAP_NODE := 118.0           # oda butonu kenarı

# Bir savaş/oda çözülünce RunManager sıradaki odaları sunar. Haritayı çiz, rota seçtir.
func _on_route_requested(run_map, options: Array) -> void:
	tm = null
	_clear_bodies()
	_clear_menu()
	_clear_map()
	status_label.text = "🗺 ROTA SEÇ — %s" % _progress_text()
	status_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	if run_map == null:
		return   # lineer akış (route beklenmez) — güvenlik
	_map_layer = Node2D.new()
	_map_layer.z_index = 20
	add_child(_map_layer)

	# Gösterim penceresi: seçilecek sütunun bir öncesinden birkaç ileri.
	var reach: Array = rm.current_node().next
	var target_col := int(options[0].col) if not options.is_empty() else 0
	var start_col := maxi(0, target_col - 1)
	var end_col := mini(run_map.columns.size() - 1, start_col + MAP_WINDOW - 1)
	var shown := end_col - start_col + 1
	var span := MAP_BOTTOM - MAP_TOP

	# Her gösterilen oda için ekran konumu (indeks -> Vector2). Önce hesapla (çizgiler için).
	var pos: Dictionary = {}
	for ci in range(start_col, end_col + 1):
		var col_rooms: Array = run_map.columns[ci]
		var rel := ci - start_col
		var y := MAP_BOTTOM - (span * float(rel) / float(maxi(1, shown - 1)))
		var w := col_rooms.size()
		for r in range(w):
			var x := MAP_X0 + (MAP_X1 - MAP_X0) * (float(r) + 0.5) / float(w)
			pos[col_rooms[r]] = Vector2(x, y)

	# Bağlantı çizgileri (oda -> sonraki odalar), butonların ALTINDA.
	for idx in pos.keys():
		for nxt in _room_next_rooms(run_map, idx):
			if pos.has(nxt):
				var line := Line2D.new()
				line.add_point(pos[idx])
				line.add_point(pos[nxt])
				line.width = 5.0
				line.default_color = Color(0.4, 0.5, 0.7, 0.5)
				line.z_index = 0
				_map_layer.add_child(line)

	# Oda butonları.
	for idx in pos.keys():
		var node: RunNode = run_map.nodes[idx]
		var reachable: bool = idx in reach
		var btn := Button.new()
		btn.text = "%s\n%s" % [_room_icon(node), _room_short(node)]
		btn.position = pos[idx] - Vector2(MAP_NODE * 0.5, MAP_NODE * 0.5)
		var accent := _room_color(node) if reachable else Color(0.35, 0.35, 0.42)
		_style_button(btn, accent, MAP_NODE, MAP_NODE, 22)
		btn.disabled = not reachable
		if reachable:
			btn.pressed.connect(_on_route_chosen.bind(idx))
			_pulse_button(btn)
		else:
			btn.modulate = Color(1, 1, 1, 0.55)
		_map_layer.add_child(btn)

func _on_route_chosen(index: int) -> void:
	_clear_map()
	rm.choose(index)

func _clear_map() -> void:
	if _map_layer != null:
		_map_layer.queue_free()
		_map_layer = null

# Bir odanın harita komşusu ODALARI (CHOICE ara düğümünü atlar).
func _room_next_rooms(run_map, idx: int) -> Array:
	var out: Array = []
	for ni in run_map.nodes[idx].next:
		var nn: RunNode = run_map.nodes[ni]
		if nn.type == RunNode.Type.CHOICE:
			for ri in nn.next:
				out.append(ri)
		elif nn.is_room():
			out.append(ni)
	return out

func _room_icon(node: RunNode) -> String:
	match node.type:
		RunNode.Type.ELITE: return "☠"
		RunNode.Type.BOSS: return "👑"
		RunNode.Type.HEAL: return "❤"
		RunNode.Type.TREASURE: return "🎁"
	return "⚔"

func _room_short(node: RunNode) -> String:
	match node.type:
		RunNode.Type.ELITE: return "ELİT"
		RunNode.Type.BOSS: return "BOSS"
		RunNode.Type.HEAL: return "DİNLEN"
		RunNode.Type.TREASURE: return "HAZİNE"
	return "SAVAŞ"

func _room_color(node: RunNode) -> Color:
	match node.type:
		RunNode.Type.ELITE: return Color(1.0, 0.55, 0.3)
		RunNode.Type.BOSS: return Color(0.9, 0.3, 0.35)
		RunNode.Type.HEAL: return Color(0.4, 0.85, 0.5)
		RunNode.Type.TREASURE: return Color(0.95, 0.8, 0.3)
	return Color(0.6, 0.75, 1.0)

# Savaşsız oda (HEAL/TREASURE) çözüldü — kısa bildirim + endless derinlik ilerlet.
func _on_room_resolved(node: RunNode) -> void:
	if node.type == RunNode.Type.HEAL:
		_flash("❤ DİNLENME — parti iyileşti", Color(0.4, 0.85, 0.5), 1.6)
	elif node.type == RunNode.Type.TREASURE:
		var relic = node.data.get("relic", null)
		var rn: String = relic.display_name if relic != null else "hazine"
		_flash("🎁 HAZİNE — %s + orb" % rn, Color(0.95, 0.8, 0.3), 1.8)
	_advance_depth()

# Endless: bir oda temizlendi -> derinlik + altın biriktir (ölümde banka edilir).
func _advance_depth() -> void:
	if not run_state.endless:
		return
	run_state.depth += 1
	run_state.gold += ENDLESS_GOLD_BASE + run_state.depth * 2

# =========================================================================
#  SAVAŞ kurulumu (run-içi loadout -> geçici Character)
# =========================================================================

func _start_battle(enemies: Array) -> void:
	if run_state.endless:
		_world_index = floori(run_state.depth / 4.0) % 5
		_update_world()
	# Yeni savaş -> önceki savaşın erteleme/anim durumunu temizle.
	_pending_end = false
	_end_delay = 0.0
	_last_skill = null
	_next_turn_delay = 0.0
	# Aktif kural kümesi: run relic'leri + takılı ekipman (aynı hook desenini paylaşır).
	var effects := run_state.relic_set()
	for eq in Meta.equipped_list():
		effects.add(eq)
	tm = TurnManager.new(BattleConfig.new(), effects)
	tm.turn_started.connect(_on_turn_started)
	tm.input_requested.connect(_on_input_requested)
	tm.action_selected.connect(_on_action_selected)
	tm.damage_resolved.connect(_on_damage_resolved)
	tm.dot_applied.connect(_on_dot_applied)
	tm.stun_skipped.connect(_on_stun_skipped)
	tm.battle_ended.connect(_on_battle_ended)

	# Her loadout -> geçici Character (draft edilmiş beceriler + run max HP).
	var party_chars: Array = []
	for lo in run_state.ordered_loadouts():
		var c := Character.new()
		c.id = lo.character.id
		c.display_name = lo.character.display_name
		c.element_pair = lo.character.element_pair
		c.max_hp = lo.max_hp()
		c.speed = lo.character.speed
		# HASAR upgrade'i: becerileri kopyala, flat bonus ekle (katalog paylaşımlı —
		# orijinali mutasyona uğratma).
		var pb: int = Meta.power_bonus(lo.character.id)
		var sk: Array[Skill] = []
		for s in lo.available_skills():
			if pb > 0:
				var s2: Skill = s.duplicate()
				s2.base_damage += pb
				sk.append(s2)
			else:
				sk.append(s)
		c.skills = sk
		party_chars.append(c)

	tm.start_battle(party_chars, enemies)

	# Taşınan HP + şarjı Combatant'lara yaz (start_battle max_hp ile doldurur,
	# şarjı 0 kurar). Şarj waveler arası taşınır (bir önceki savaştan %20 düşük).
	for cmb in tm.combatants:
		if cmb.side == Combatant.Side.PARTY:
			var lo := run_state.loadout(cmb.source.id)
			if lo != null:
				cmb.hp = clampi(lo.current_hp, 1, lo.max_hp())
				cmb.charge = clampi(lo.charge, 0, cmb.charge_max)

	_build_bodies()
	# ELITE savaş görsel olarak ayrışır (risk/reward uyarısı).
	var node := rm.current_node() if rm != null else null
	if node != null and node.is_elite():
		status_label.text = "☠ ELİT SAVAŞ — %s" % _progress_text()
		status_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.3))
		_flash("☠ ELİT — çift orb!", Color(1.0, 0.55, 0.3), 1.8)
	else:
		status_label.text = "SAVAŞ — %s" % _progress_text()
		status_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	# Bir önceki CHOICE'ta rün dönüşümü olduysa: ilk turun başında reveal animasyonu.
	_reveal_transform()

# =========================================================================
#  SAVAŞ olayları (TurnManager) — büyük ölçüde eski host mantığı
# =========================================================================

func _on_turn_started(actor: Combatant) -> void:
	_clear_menu()
	if actor.side == Combatant.Side.PARTY:
		status_label.text = "✨ %s SIRASI — BECERİ SEÇ" % actor.display_name().to_upper()
		_build_skill_menu(actor)
	else:
		status_label.text = "⚔️ %s SIRASI (DÜŞMAN)" % actor.display_name().to_upper()

func _build_skill_menu(actor: Combatant) -> void:
	# Savaş menüsü konumu/aralığı (CHOICE ekranı değeri değiştirmiş olabilir).
	skill_menu.position = Vector2(90, _ground_y() + 110.0)
	skill_menu.add_theme_constant_override("separation", 10)
	var pm: float = tm.config.perfect_multiplier   # PERFECT'teki maks potansiyel hasar
	for s in actor.skills():
		var btn := Button.new()
		var dmg: int = int(round(s.base_damage * pm))
		var icon := _skill_icon(s)
		var accent := _skill_color(s)

		# Sembolik + renk odaklı: büyük ikon önce, isim, sade hasar sayısı. Sabit jest
		# dizisi (◀▶●) KALDIRILDI — dizi her cast'te rastgele üretiliyor (bkz RhythmMinigame).
		if s.requires_charge:
			if actor.is_charged():
				btn.text = "%s  %s   ⚡%d" % [icon, s.display_name.to_upper(), dmg]
				accent = Color(1.0, 0.85, 0.2)   # dolu ult: altın
			else:
				btn.text = "%s  %s   (ŞARJ %d/%d)" % [icon, s.display_name.to_upper(), actor.charge, actor.charge_max]
				btn.disabled = true
		else:
			btn.text = "%s  %s   %d hasar" % [icon, s.display_name, dmg]

		_style_button(btn, accent, 94.0)
		btn.pressed.connect(_on_skill_chosen.bind(s))
		skill_menu.add_child(btn)

# Beceriyi tek bir büyük sembole indir (isim kimse bilmesin diye görsel ipucu).
func _skill_icon(s: Skill) -> String:
	match s.id:
		"ember_bolt": return "🔥"
		"inferno": return "🌋"
		"plasma_bolt": return "⚡"
		"plasma_storm": return "🌩"
	var r := s.rune_id.to_lower()
	if s.requires_charge:
		return "🌟"
	if "storm" in r or "plasma" in r or "plazma" in r:
		return "⚡"
	if "frost" in r or "buz" in r:
		return "❄"
	return "🔥"

# Beceri element rengi (buton çerçevesi).
func _skill_color(s: Skill) -> Color:
	var r := s.rune_id.to_lower()
	if "ember" in r or "fire" in r or "ateş" in r:
		return Color(1.0, 0.45, 0.15)
	if "storm" in r or "plasma" in r or "plazma" in r or "yıldırım" in r:
		return Color(0.85, 0.5, 1.0)
	if "frost" in r or "buz" in r:
		return Color(0.3, 0.8, 1.0)
	return Color(0.9, 0.75, 0.3)

func _on_skill_chosen(skill: Skill) -> void:
	var target := _lowest_hp_enemy()
	if target == null:
		return
	_clear_menu()
	tm.select_action(skill, target)   # -> input_requested -> _on_input_requested

# =========================================================================
#  RİTİM minigame (Piano Tiles) — büyü öncesi zamanlama, sonucu motora submit
# =========================================================================

# Kombo tile sayısı: run içinde node_index ilerledikçe uzar (2 -> ... -> cap).
func _combo_length() -> int:
	var idx: int = run_state.node_index if run_state != null else 0
	return clampi(COMBO_BASE_LEN + int(idx / 2), COMBO_BASE_LEN, COMBO_MAX_LEN)

# TurnManager beceri seçilince diziyi ister; kombo ritim minigame'i aç.
func _on_input_requested(sequence: InputSequence) -> void:
	if sequence == null or sequence.steps.is_empty():
		# Girdi gerekmiyor -> anında PERFECT.
		_flash_input_result(InputEvaluator.Result.PERFECT)
		if tm != null:
			tm.submit_input(InputEvaluator.Result.PERFECT)
		return
	# Kombo bağlamı: hedef + beceri + "hepsi-PERFECT" nihai hasar (PF; per-tile sayı payı).
	_combo_target = tm.pending_target
	_combo_skill = tm.pending_skill
	_combo_pf = 0.0
	if _combo_skill != null and _combo_target != null:
		var pf_b := BattleDamage.compute(_combo_skill, tm.config.perfect_multiplier,
			_combo_target, tm.config, tm.relics)
		_combo_pf = float(pf_b.final_damage)
	_suppress_aggregate_fx = true   # per-tile FX gösterilecek; aggregate FX bastır
	_rhythm = RhythmMinigame.new()
	_rhythm.z_index = 30   # ÜST TABAKA: Can barları, karakterler ve arka planın üstünde çizilir!
	_rhythm.tile_resolved.connect(_on_tile_resolved)
	_rhythm.finished.connect(_on_rhythm_finished)
	add_child(_rhythm)
	# Can barlarının üstündeki gökyüzü bölgesinde konumlandır (y = ~600)
	var ry_y := maxf(220.0, _ground_y() - 870.0)
	# Waveler (tur) geçtikçe piano tiles hızlanır. round_index 1'den başlar => ilk wave 1.0x.
	var waves_passed: int = maxi(0, (tm.round_index if tm != null else 1) - 1)
	var wave_scale := 1.0 + float(waves_passed) * RHYTHM_SPEEDUP_PER_WAVE
	# Adaptive: oyuncunun gerçek oynayışına göre (kalıcı profil + oturum) hızı ölçekle.
	# 20 de 60 yaş da zevk alsın; kötü gün/el değişimi oturum skill'iyle yakalanır.
	var adaptive := Meta.rhythm_speed_scale()
	# Endless OVERRIDE: ritim derinlikle SÜREKLİ hızlanır; adaptive yavaşlatma tabanı ezemez
	# (yalnız daha da hızlandırabilir). Campaign'de adaptive iki yönlü kalır.
	if run_state.endless:
		adaptive = maxf(adaptive, 1.0 + float(run_state.depth) * ENDLESS_RHYTHM_RAMP)
	var speed_scale := wave_scale * adaptive
	_rhythm.setup(_combo_length(), Rect2(90, ry_y, 900, 560), speed_scale)

# Tutturulan her tile bir "vuruş": caster'dan hedefe escalating fireball + hasar sayısı.
# Finisher (son tile) en büyük ölçek + ult pozu + en büyük sayı. fraction<=0 -> ıska (FX yok).
func _on_tile_resolved(index: int, total: int, _result: int, is_finisher: bool, fraction: float) -> void:
	if fraction <= 0.0 or tm == null or _combo_target == null or not _combo_target.is_alive():
		return
	var caster := tm.active
	if caster == null:
		return
	var rune := _combo_skill.rune_id if _combo_skill != null else "ember"
	_play_anim(caster, "ult" if is_finisher else "cast")
	var from := _body_center(caster) + Vector2(75.0 * _facing(caster), -12.0)
	var to := _body_center(_combo_target)
	# Escalation: ilk tile küçük -> son normal tile büyük; finisher dev.
	var denom: float = float(maxi(1, total - 1))
	var scale := lerpf(0.55, 0.9, float(index) / denom)
	if is_finisher:
		scale = 1.3
	var impact_t := _fx_projectile(from, to, caster, rune, scale)
	var dmg := int(round(_combo_pf * fraction))
	var col := _fx_color(rune)
	var tgt := _combo_target
	var big := is_finisher
	# ULTIMATE finisher: temel büyünün finisher'ından AYRI, tatmin edici bir final —
	# ekran flaşı + sarsıntı + (aoe ise) tüm düşmanlarda parlama.
	var is_ult := _combo_skill != null and _combo_skill.requires_charge
	var is_aoe := _combo_skill != null and _combo_skill.aoe
	var tw := create_tween()
	tw.tween_interval(impact_t)
	tw.tween_callback(func() -> void:
		if is_instance_valid(self) and tgt != null and tgt.is_alive():
			if tgt.side == Combatant.Side.PARTY:
				_play_anim(tgt, "hurt")
			else:
				_play_enemy_anim(tgt, "hurt")
			_impact_burst(_body_center(tgt), col, (2.1 if is_ult else 1.5) if big else 0.9)
			_float_damage(tgt, dmg, col)
			if big and is_ult:
				_ultimate_flourish(rune, is_aoe))

# Kombo bitti -> skoru float çarpana çevir, motora ver (fail-soft floor). broke -> flash.
func _on_rhythm_finished(payload: Dictionary) -> void:
	if _rhythm != null:
		_rhythm.queue_free()
		_rhythm = null
	var score: float = float(payload.get("combo_score", 0.0))
	var broke: bool = bool(payload.get("broke", false))
	# Adaptive zorluk: bu cast'in performansını skill profiline işle (bir sonraki hızı ayarlar).
	Meta.record_rhythm_result(score, broke)
	if broke:
		_flash("💥 KOMBO KIRILDI!", Color(1.0, 0.4, 0.35), 1.2)
	if tm != null:
		var mult: float = maxf(tm.config.miss_multiplier, tm.config.perfect_multiplier * score)
		tm.submit_input_multiplier(mult, score)   # -> _on_damage_resolved (aggregate FX bastırılı)
	_suppress_aggregate_fx = false

func _flash_input_result(result: int) -> void:
	var txt := InputEvaluator.result_label(result)
	var col := Color(1.0, 0.85, 0.25)
	if result == InputEvaluator.Result.PERFECT:
		col = Color(0.4, 1.0, 0.5)
	elif result == InputEvaluator.Result.MISS:
		col = Color(0.9, 0.5, 0.4)
	_flash(txt, col, 1.0)

# Beceri seçildi (oyuncu girdisi ya da düşman AI) -> saldırı animasyonunu seçmek için sakla.
func _on_action_selected(skill: Skill, _target: Combatant) -> void:
	_last_skill = skill

func _on_damage_resolved(b: DamageBreakdown, attacker: Combatant, target: Combatant) -> void:
	if b.missed:
		status_label.text = "KÖR EDEN PLAZMA · DÜŞMAN ISKALADI!"
		_play_enemy_anim(attacker, "attack")
		_flash("ISKA!", Color("fff4b5"), 0.9)
		_next_turn_delay = NEXT_TURN_PAUSE
		return
	status_label.text = "⚔️ %s ➔ %s : %d HASAR" % [
		attacker.display_name().to_upper(), target.display_name().to_upper(), b.final_damage]
	# Kombo action'ı: projectile/hasar sayısı per-tile'da gösterildi (bkz _on_tile_resolved).
	# Aggregate FX'i bastır; sadece sıra geçişi için bekleme kur (HP barı motor uyguladı).
	if _suppress_aggregate_fx:
		_next_turn_delay = maxf(NEXT_TURN_PAUSE, 0.9)
		return
	# Saldıran pozu: party cast/ult, düşman attack.
	if attacker.side == Combatant.Side.PARTY:
		var atk_anim := "ult" if (_last_skill != null and _last_skill.requires_charge) else "cast"
		_play_anim(attacker, atk_anim)
	else:
		_play_enemy_anim(attacker, "attack")
	# Büyü efekti (carrier'a göre): mermi/ışın/AoE -> caster'dan hedefe. Efekt VARIŞINDA
	# hedef hurt + hasar sayısı + impact patlaması gösterilir (görsel senkron).
	var carrier := _last_skill.carrier if _last_skill != null else "Projectile"
	var rune := _last_skill.rune_id if _last_skill != null else ""
	var impact_t := _spawn_spell_fx(attacker, target, carrier, rune)
	_schedule_impact(target, b.final_damage, rune, carrier, impact_t)
	_next_turn_delay = maxf(NEXT_TURN_PAUSE, impact_t + 0.45)

# ---- Büyü görsel efektleri (SpellFX) --------------------------------------
# carrier: Projectile (uçan top), Beam (anlık ışın), Area (ateş meteor+AoE),
# Storm (elektrik AoE). rune_id renk verir (ember=turuncu, storm=mor, ""=nötr/pale).

func _fx_color(rune: String) -> Color:
	match rune:
		"ember": return Color(1.0, 0.6, 0.2)
		"storm": return Color(0.65, 0.5, 1.0)
		_: return Color(0.82, 0.88, 1.0)

# Bir combatant sprite'ının dünya merkezi (sprite'lar merkezli konumlanır).
func _body_center(c: Combatant) -> Vector2:
	var bd: Variant = _bodies.get(c)
	if bd == null:
		return Vector2.ZERO
	var spr: Variant = bd.get("sprite")
	return (spr as Node2D).position if spr != null else Vector2.ZERO

func _facing(c: Combatant) -> float:
	return 1.0 if c.side == Combatant.Side.PARTY else -1.0

# Efekti spawn eder, IMPACT'e kadar geçen süreyi (saniye) döndürür.
func _spawn_spell_fx(caster: Combatant, target: Combatant, carrier: String, rune: String) -> float:
	var from := _body_center(caster) + Vector2(75.0 * _facing(caster), -12.0)
	var to := _body_center(target)
	match carrier:
		"Beam":
			return _fx_beam(from, to, rune)
		"Area":
			return _fx_area(to, rune)
		"Storm":
			return _fx_storm_aoe(to, rune)
		_:
			return _fx_projectile(from, to, caster, rune)

# Uçan mermi: ember=fireball, storm=plazma orb, düşman/nötr=pale fireball.
# scale: kombo escalation için ölçek (finisher büyük). Varsayılan eski davranış.
func _fx_projectile(from: Vector2, to: Vector2, caster: Combatant, rune: String, scale := 0.7) -> float:
	var s := Sprite2D.new()
	s.texture = FX_PLASMA_ORB if rune == "storm" else FX_FIREBALL
	s.position = from
	s.scale = Vector2(scale, scale)
	s.flip_h = _facing(caster) < 0.0
	if rune not in ["ember", "storm"]:
		s.modulate = _fx_color(rune)
	add_child(s)
	var dur := 0.34
	var tw := create_tween()
	tw.tween_property(s, "position", to, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(s, "rotation", (to - from).angle() * 0.15, dur)
	tw.tween_callback(s.queue_free)
	return dur

# Anlık ışın: caster elinden hedefe uzatılmış beam sprite + impact spark.
func _fx_beam(from: Vector2, to: Vector2, rune: String) -> float:
	var beam := Sprite2D.new()
	beam.texture = FX_BEAM
	beam.centered = false
	var dir := to - from
	var blen := dir.length()
	var texw := float(FX_BEAM.get_width())
	beam.position = from
	beam.rotation = dir.angle()
	beam.scale = Vector2(blen / texw, 1.1)
	if rune not in ["ember", "storm"]:
		beam.modulate = _fx_color(rune)
	add_child(beam)
	var tw := create_tween()
	tw.tween_interval(0.22)
	tw.tween_property(beam, "modulate:a", 0.0, 0.15)
	tw.tween_callback(beam.queue_free)
	return 0.16

# Ateş AoE (Inferno): rainbow meteor hedef kümesine düşer + ateş patlaması.
func _fx_area(to: Vector2, _rune: String) -> float:
	var comet := Sprite2D.new()
	comet.texture = FX_COMET
	comet.position = to + Vector2(320.0, -520.0)
	comet.scale = Vector2(0.9, 0.9)
	comet.rotation = deg_to_rad(120.0)
	add_child(comet)
	var dur := 0.42
	var tw := create_tween()
	tw.tween_property(comet, "position", to + Vector2(0, -20), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(comet.queue_free)
	# Tüm düşmanlarda ateş parlaması (AoE) — impact anında.
	_flash_all_enemies(dur, Color(1.0, 0.55, 0.2))
	return dur

# Elektrik AoE (Plazma Fırtınası): storm sprite düşman kümesi üstünde çakar.
func _fx_storm_aoe(to: Vector2, _rune: String) -> float:
	var st := Sprite2D.new()
	st.texture = FX_STORM
	st.position = to + Vector2(-40, -60)
	st.scale = Vector2(0.7, 0.7)
	st.modulate.a = 0.0
	add_child(st)
	var tw := create_tween()
	tw.tween_property(st, "modulate:a", 1.0, 0.12)
	tw.tween_interval(0.22)
	tw.tween_property(st, "modulate:a", 0.0, 0.18)
	tw.tween_callback(st.queue_free)
	_flash_all_enemies(0.3, Color(0.6, 0.5, 1.0))
	return 0.3

# AoE: tüm canlı düşmanlarda kısa renk parlaması + hurt (impact hissi).
func _flash_all_enemies(delay: float, col: Color) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		for c in _bodies.keys():
			if not _bodies[c].get("is_party", false) and c.is_alive():
				_play_enemy_anim(c, "hurt")
				_impact_burst(_body_center(c), col, 0.9))

# IMPACT: efekt varışında hedef hurt + hasar sayısı + patlama (tek hedef).
func _schedule_impact(target: Combatant, dmg: int, rune: String, carrier: String, t: float) -> void:
	var col := _fx_color(rune)
	var tw := create_tween()
	tw.tween_interval(t)
	tw.tween_callback(func() -> void:
		if carrier not in ["Area", "Storm"]:   # AoE hurt'ü _flash_all_enemies yapar
			if target.is_alive():
				if target.side == Combatant.Side.PARTY:
					_play_anim(target, "hurt")
				else:
					_play_enemy_anim(target, "hurt")
			_impact_burst(_body_center(target), col, 1.1)
		_float_damage(target, dmg, col))

# Patlama: YUVARLAK (kare sprite kötü duruyordu). Dolgu disk + genişleyen halka,
# ikisi de büyüyüp solar.
func _impact_burst(pos: Vector2, col: Color, sc: float) -> void:
	var base_r := 46.0 * sc
	# Dolgu parıltı diski.
	var disk := _circle_poly(base_r, Color(col.r, col.g, col.b, 0.85))
	disk.position = pos
	disk.z_index = 40
	disk.scale = Vector2(0.25, 0.25)
	add_child(disk)
	var tw := create_tween()
	tw.tween_property(disk, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(disk, "modulate:a", 0.0, 0.30)
	tw.tween_callback(disk.queue_free)
	# Genişleyen ince halka (şok dalgası).
	var ring := _ring_line(base_r, Color(1, 1, 1, 0.9), 5.0)
	ring.position = pos
	ring.z_index = 41
	add_child(ring)
	var tw2 := create_tween()
	tw2.tween_property(ring, "scale", Vector2(1.9, 1.9), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.parallel().tween_property(ring, "modulate:a", 0.0, 0.32)
	tw2.tween_callback(ring.queue_free)

# ULTIMATE final gösterisi: ekran flaşı + kamera sarsıntısı + (aoe) tüm düşman parlaması.
# Temel büyüde ÇAĞRILMAZ — ultimate'i görsel olarak ayırır (istek: ult daha tatmin edici).
func _ultimate_flourish(rune: String, is_aoe: bool) -> void:
	var col := _fx_color(rune)
	_screen_flash(col, 0.45)
	_screen_shake(22.0, 0.45)
	if is_aoe:
		_flash_all_enemies(0.04, col)

# Tam ekran renk flaşı (hızlı yüksel, yavaş sön).
func _screen_flash(col: Color, peak := 0.4) -> void:
	var f := ColorRect.new()
	f.color = Color(col.r, col.g, col.b, 0.0)
	f.size = Vector2(1080.0, maxf(1920.0, get_viewport_rect().size.y))
	f.position = Vector2.ZERO
	f.z_index = 45
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	var tw := create_tween()
	tw.tween_property(f, "color:a", peak, 0.07)
	tw.tween_property(f, "color:a", 0.0, 0.38)
	tw.tween_callback(f.queue_free)

# Kamera sarsıntısı: kökü (self) kısa süre titret, sonra sıfıra döndür.
func _screen_shake(intensity := 18.0, dur := 0.4) -> void:
	var steps := 6
	var tw := create_tween()
	for i in range(steps):
		var amp: float = intensity * (1.0 - float(i) / float(steps))
		var off := Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
		tw.tween_property(self, "position", off, dur / float(steps))
	tw.tween_property(self, "position", Vector2.ZERO, dur / float(steps))

# Dolu daire çokgeni (merkezli).
func _circle_poly(r: float, col: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	var seg := 28
	for i in range(seg):
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * r)
	poly.polygon = pts
	poly.color = col
	return poly

# Kapalı daire çizgisi (halka).
func _ring_line(r: float, col: Color, w: float) -> Line2D:
	var line := Line2D.new()
	var pts := PackedVector2Array()
	var seg := 32
	for i in range(seg + 1):
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * r)
	line.points = pts
	line.width = w
	line.default_color = col
	return line

# Yükselen hasar sayısı.
func _float_damage(target: Combatant, dmg: int, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = str(dmg)
	lbl.add_theme_font_size_override("font_size", 46)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.position = _body_center(target) + Vector2(-30, -90)
	lbl.z_index = 50
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -70), 0.7).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.tween_callback(lbl.queue_free)

# Combatant için düşman sprite animasyonu (güvenli).
func _play_enemy_anim(c: Combatant, anim: String) -> void:
	var b: Variant = _bodies.get(c)
	if b == null:
		return
	var spr: Variant = b.get("sprite")
	if spr != null:
		_enemy_play(spr as AnimatedSprite2D, anim)

func _on_dot_applied(c: Combatant, amount: int) -> void:
	status_label.text = "%s yandı: %d hasar" % [c.display_name(), amount]
	if c.side == Combatant.Side.PARTY and c.is_alive():
		_play_anim(c, "hurt")

func _on_stun_skipped(c: Combatant) -> void:
	status_label.text = "%s sersemledi — sıra atlandı" % c.display_name()

# Savaş bitti. Sıradaki node'u HEMEN tetiklemez — önce ölüm/zafer/ult animasyonlarının
# oynaması için BATTLE_END_PAUSE kadar bekler (oyuncu ne olduğunu görsün). Bekleme
# _process'te işlenir, sonunda _finalize_battle çağrılır.
func _on_battle_ended(winner_side: int) -> void:
	_clear_menu()
	_pending_won = winner_side == Combatant.Side.PARTY
	# Zafer "sevinme" animasyonu KALDIRILDI (kötü duruyordu) — kazanınca idle kalır.
	# Ölümler _update_bodies'te oynar.
	_pending_end = true
	_end_delay = BATTLE_END_PAUSE

# Bekleme bitti -> ödül/HP kaydı + sıradaki node. rm.report_battle_result burada tm'i
# değiştirir; _process pending bloğu bu çağrıdan sonra frame'den çıkar.
func _finalize_battle() -> void:
	var won := _pending_won
	if won:
		# Yenilen düşman başına 1 orb (CHOICE'ta board'a dökülür). ELITE savaş orb'u
		# katlar (risk/reward: daha güçlü düşman -> daha yüksek ödül).
		var foes := 0
		for cmb in tm.combatants:
			if cmb.side == Combatant.Side.ENEMY:
				foes += 1
		var node := rm.current_node() if rm != null else null
		var mult := ELITE_ORB_MULT if (node != null and node.is_elite()) else 1
		run_state.orbs += foes * mult
		# Battle-pass: her savaş zaferi mastery kazandırır (elite/boss ekstra). Ödül
		# ANA EKRANDA elle toplanır (Meta.claim_next); burada sadece "hazır" toast'u.
		var gain := Meta.MASTERY_PER_WIN
		if node != null and node.is_elite():
			gain += Meta.MASTERY_ELITE_BONUS
		elif node != null and node.type == RunNode.Type.BOSS:
			gain += Meta.MASTERY_BOSS_BONUS
		var before_claimable := Meta.claimable_count()
		Meta.add_mastery(gain)
		if Meta.claimable_count() > before_claimable:
			_flash("🎁 Yeni mastery ödülü hazır — ANA EKRAN'da TOPLA!", Color(1.0, 0.85, 0.35), 2.4)
		_advance_depth()   # endless: temizlenen savaş odası derinlik + altın biriktirir
		_save_party_hp()
	# report_battle_result sıradaki düğümü tetikler (battle/choice/run_ended).
	rm.report_battle_result(won)

# Hayatta kalan parti HP'sini taşı; düşen üyeyi %25 ile dirilt (soft-lock önle).
func _save_party_hp() -> void:
	for cmb in tm.combatants:
		if cmb.side != Combatant.Side.PARTY:
			continue
		var lo := run_state.loadout(cmb.source.id)
		if lo == null:
			continue
		if cmb.hp > 0:
			lo.current_hp = cmb.hp
			lo.store_charge(cmb.charge, WAVE_CHARGE_DECAY)   # şarj taşınır, %20 düşer
		else:
			lo.current_hp = max(1, int(round(lo.max_hp() * REVIVE_FRACTION)))
			lo.charge = 0   # düşen üye şarjını kaybeder

# =========================================================================
#  Görseller + girdi + döngü
# =========================================================================

func _build_bodies() -> void:
	var party_i := 0
	var enemy_i := 0
	var gy := _ground_y()
	var sprite_h: float = 256.0 * WIZARD_SCALE   # ~230 px
	for c in tm.combatants:
		var is_party: bool = c.side == Combatant.Side.PARTY
		var idx: int = party_i if is_party else enemy_i
		# Zemin çizgisi: arka plandaki tuğla döşeme üstü (~y1275) + biraz gömülü.
		# Ek üyeler yukarı doğru istiflenir.
		var feet_y: float = gy - idx * BODY_GAP
		if is_party:
			# Animasyonlu büyücü sprite'ı — ayakları zemine basar (sol taraf).
			# Sprite seti güncel formdan gelir (Ember->fire, Plazma->arcane).
			var spr: AnimatedSprite2D = WIZARD_SCENE.instantiate()
			spr.sprite_frames = _player_frames(c)
			spr.scale = Vector2(WIZARD_SCALE, WIZARD_SCALE)
			spr.position = Vector2(140.0, feet_y - sprite_h * 0.5)   # merkezli sprite
			spr.animation_finished.connect(_on_sprite_anim_finished.bind(spr))
			spr.play("idle")
			add_child(spr)
			# İsim/yazı YOK — baş üstünde can barı + enerji barı.
			var top: float = feet_y - sprite_h
			var bx: float = 140.0 - BAR_W * 0.5
			var hp: Dictionary = _make_bar(Vector2(bx, top - 44.0))
			var en: Dictionary = _make_bar(Vector2(bx, top - 22.0))
			_bodies[c] = {
				"sprite": spr, "is_party": true, "dead_played": false,
				"hp_bar": hp["bg"], "hp_fill": hp["fill"],
				"en_bar": en["bg"], "en_fill": en["fill"],
			}
			party_i += 1
		else:
			# Düşman animasyonlu sprite'ı — sağda YATAY DİZİ (arka arkaya). İlk düşman
			# en sağda; sonrakiler sola doğru dizilir. Uçan türler havada durur (lift +
			# yumuşak hover). Derinlik için art arda hafif dikey kaydırma.
			var spr := AnimatedSprite2D.new()
			spr.sprite_frames = ENEMY_FRAMES[_enemy_sprite_key(c.source)]
			spr.flip_h = true   # party'e dönük (sprite'lar ters yöne bakıyor)
			spr.scale = Vector2.ONE * ENEMY_SCALE * (96.0 / spr.sprite_frames.get_frame_texture("idle", 0).get_width())
			var eh: float = 96.0 * ENEMY_SCALE
			var ex: float = 950.0 - idx * ENEMY_COL_GAP
			var depth_y: float = float(idx % 2) * 44.0        # zig-zag derinlik
			var floats: bool = _enemy_floats(c.source)
			var lift: float = ENEMY_FLOAT_LIFT if floats else 0.0
			var cy: float = gy + depth_y - eh * 0.5 - lift
			spr.position = Vector2(ex, cy)
			spr.z_index = idx                                 # öndekiler üstte
			spr.animation_finished.connect(_on_enemy_anim_finished.bind(spr))
			spr.play("idle")
			add_child(spr)
			if floats:
				_hover(spr)                                   # havada süzülme
			var bx2: float = ex - BAR_W * 0.5
			var ehp: Dictionary = _make_bar(Vector2(bx2, cy - eh * 0.5 - 6.0))
			_bodies[c] = {
				"sprite": spr, "is_party": false, "dead_played": false,
				"hp_bar": ehp["bg"], "hp_fill": ehp["fill"],
			}
			enemy_i += 1

# Düşman kaynağını 3 sprite setinden birine eşle.
func _enemy_sprite_key(src) -> String:
	var eid: String = src.id
	if eid.begins_with("boss"):
		return "dragon"
	if eid.begins_with("brute") or eid.begins_with("mauler") or eid.begins_with("warden") or eid == "golem":
		return "dev"
	return "goblin"

# Uçan düşman mı? (havada durur + hover). Ejderha (boss) ve okçu havadadır.
func _enemy_floats(src) -> bool:
	var eid: String = src.id
	return _enemy_sprite_key(src) == "dragon" or eid.begins_with("archer")

# Sonsuz yumuşak süzülme (uçan düşmanlar için).
func _hover(spr: Node2D) -> void:
	var base_y: float = spr.position.y
	var tw := create_tween().bind_node(spr).set_loops()
	tw.tween_property(spr, "position:y", base_y - 26.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(spr, "position:y", base_y, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Düşman geçici animasyonu bitince idle'a dön (death/idle hariç).
func _on_enemy_anim_finished(spr: AnimatedSprite2D) -> void:
	if spr.animation in ["attack", "hurt"]:
		spr.play("idle")

# Stat barı: koyu arka çerçeve + dolgu. {bg, fill} döner.
func _make_bar(pos: Vector2) -> Dictionary:
	var bg := ColorRect.new()
	bg.size = Vector2(BAR_W, BAR_H)
	bg.color = Color(0.05, 0.05, 0.08, 0.72)
	bg.position = pos
	bg.z_index = 2
	add_child(bg)
	var fill := ColorRect.new()
	fill.size = Vector2(BAR_W - BAR_PAD * 2.0, BAR_H - BAR_PAD * 2.0)
	fill.position = Vector2(BAR_PAD, BAR_PAD)   # bg'ye göreli
	bg.add_child(fill)                          # bg free -> fill de gider
	return {"bg": bg, "fill": fill}

# Dolgu barını orana (0..1) ayarla + renk uygula.
func _set_bar(fill: ColorRect, ratio: float, col: Color) -> void:
	var r: float = clampf(ratio, 0.0, 1.0)
	fill.size.x = (BAR_W - BAR_PAD * 2.0) * r
	fill.color = col

# Geçici animasyonlar bitince idle'a dön; death/victory son karede kalır (loop/hold).
func _on_sprite_anim_finished(spr: AnimatedSprite2D) -> void:
	if spr.animation in ["cast", "hurt", "walk", "ult", "levelup", "victory"]:
		spr.play("idle")

# Bir combatant için (varsa) sprite animasyonu oynat.
func _play_anim(c: Combatant, anim: String) -> void:
	var b: Variant = _bodies.get(c)
	if b == null:
		return
	var spr: Variant = b.get("sprite")
	if spr != null:
		(spr as AnimatedSprite2D).play(anim)

func _clear_bodies() -> void:
	for c in _bodies.keys():
		var b: Dictionary = _bodies[c]
		if b.has("sprite"):
			(b["sprite"] as Node).queue_free()
		if b.has("box"):
			(b["box"] as Node).queue_free()
		# Bar container'ları (fill child olarak birlikte gider).
		for k in ["hp_bar", "en_bar"]:
			if b.has(k):
				(b[k] as Node).queue_free()
	_bodies.clear()

func _update_bodies() -> void:
	for c in _bodies.keys():
		var b: Dictionary = _bodies[c]
		var hp_ratio: float = float(c.hp) / float(maxi(1, c.source.max_hp))
		_set_bar(b["hp_fill"], hp_ratio, _hp_color(hp_ratio))
		if b["is_party"]:
			# Enerji (şarj) barı — dolunca altın parıltı.
			var cr: float = float(c.charge) / float(maxi(1, c.charge_max))
			var en_col := Color(1.0, 0.82, 0.2) if c.is_charged() else Color(0.35, 0.7, 1.0)
			_set_bar(b["en_fill"], cr, en_col)
			var spr: AnimatedSprite2D = b["sprite"]
			# Build arketip rengi: commit edilen arketip büyücüyü boyar (görsel kimlik);
			# tüm animasyonlara (idle/cast/hurt) biner. Yoksa WHITE (nötr).
			var tint := _party_tint(c)
			if not c.is_alive():
				if not b["dead_played"]:
					spr.play("death")
					b["dead_played"] = true
				spr.modulate = Color(0.55, 0.55, 0.6, 1)
			elif tm != null and c == tm.active:
				spr.modulate = Color(1.3, 1.3, 1.15, 1) * tint   # cast: arketip renginde parlar
			elif c.stunned:
				spr.modulate = Color(0.6, 0.75, 1.1, 1)
			elif c.pending_dot > 0:
				spr.modulate = Color(1.2, 0.7, 0.5, 1)
			else:
				spr.modulate = tint
		else:
			var espr: AnimatedSprite2D = b["sprite"]
			if not c.is_alive():
				if not b["dead_played"]:
					_enemy_play(espr, "death")
					b["dead_played"] = true
				espr.modulate = Color(0.55, 0.55, 0.6, 1)
			elif tm != null and c == tm.active:
				espr.modulate = Color(1.25, 1.2, 1.15, 1)
			elif c.pending_dot > 0:
				espr.modulate = Color(1.2, 0.7, 0.5, 1)
			else:
				espr.modulate = Color.WHITE

# Düşman animasyonu güvenli oynat (yoksa idle'da kal).
func _enemy_play(spr: AnimatedSprite2D, anim: String) -> void:
	if spr.sprite_frames != null and spr.sprite_frames.has_animation(anim):
		spr.play(anim)

# Can oranına göre renk: yüksek yeşil -> orta sarı -> düşük kırmızı.
func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.85, 0.75, 0.25).lerp(Color(0.35, 0.82, 0.35), (ratio - 0.5) * 2.0)
	return Color(0.85, 0.22, 0.2).lerp(Color(0.85, 0.75, 0.25), ratio * 2.0)

func _clear_menu() -> void:
	for c in skill_menu.get_children():
		c.queue_free()
	if _rhythm != null:
		_rhythm.queue_free()
		_rhythm = null
		_suppress_aggregate_fx = false

func _lowest_hp_enemy() -> Combatant:
	var best: Combatant = null
	for c in tm._alive_on(Combatant.Side.ENEMY):
		if best == null or c.hp < best.hp:
			best = c
	return best

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var unscaled_dt := float(now - _last_usec) / 1_000_000.0
	_last_usec = now

	# Geçici flash yazısı zamanla söner.
	if _flash_time > 0.0:
		_flash_time -= unscaled_dt
		if _flash_time <= 0.0:
			_flash_label.visible = false

	# KRİTİK: advance savaşı bitirebilir -> sinyal zinciri (battle_ended ->
	# report_battle_result -> choice/next/run_ended) `tm`'i null/YENİ yapar. O yüzden
	# yerel cur_tm ile çalış ve savaş-bitiren çağrıdan sonra tm değiştiyse frame'den
	# ÇIK (yoksa stale/null tm.state erişimi = wave-sonu crash).
	var cur_tm := tm
	if cur_tm == null:
		return
	# Savaş sonu ERTELEME: anim'ler (ölüm/zafer/ult) oynarken bekle, sonra finalize et.
	# Bekleme boyunca sadece görselleri güncelle; tur ilerletme YOK.
	if _pending_end:
		_end_delay -= unscaled_dt
		_update_bodies()
		overlay.update_view(cur_tm)
		if _end_delay <= 0.0:
			_pending_end = false
			_finalize_battle()
		return
	if cur_tm.state == TurnManager.State.NEXT_TURN:
		_next_turn_delay -= unscaled_dt
		if _next_turn_delay <= 0.0:
			cur_tm.advance_turn()
			if tm != cur_tm:
				return
	_update_bodies()
	overlay.update_view(cur_tm)
