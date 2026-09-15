extends RefCounted
class_name Archetype

# Bir RUN build kimliği KATMANI (Burn / Crit / Explosion). Kimlik-swap'ı (MageForm)
# DEĞİŞTİRMEZ — ÜSTÜNE biner (enhancement, bkz [[Build Arketipi — Enhancement,
# Replacement Değil]]). CHOICE'ta seçilir; aktif formu bir arketipe büründürür
# (örn. "Alev Kor Büyücü"). Combat gücü effects[] üzerinden gelir: her effect
# duck-typed kanca taşıyıcı (hook + amount), motor mevcut RelicSet mekanizması ile
# okur — bu yüzden çoğu arketip motor değişmeden çalışır.
#
#   id           : benzersiz kimlik (run içinde tekrar sunulmaz).
#   display_name : "Alev Yükü" gibi kısa ad.
#   description  : tek cümle etki (UI etiketinde gösterilir).
#   form_id      : hangi forma uygulanır ("ember"). Plazma havuzu sonra (aynı 3 model).
#   name_prefix  : form adına ön ek ("Alev" -> "Alev Kor Büyücü").
#   effects      : Array — RelicSet'e eklenen kanca taşıyıcıları (Relic ile duck-typed).
# Saf veri: Node/Engine bilmez. code_anchors durable key: Archetype.

var id: String
var display_name: String
var description: String
var form_id: String
var name_prefix: String
var effects: Array
var icon: String = "🔥"   # CHOICE kartında gösterilen sembol (arketip başına ayrı)
var tint: Color = Color.WHITE   # commit edilince büyücü sprite'ına biner (görsel kimlik)

func _init(p_id := "", p_name := "", p_desc := "", p_form_id := "", p_prefix := "", p_effects := [], p_icon := "🔥", p_tint := Color.WHITE) -> void:
	id = p_id
	display_name = p_name
	description = p_desc
	form_id = p_form_id
	name_prefix = p_prefix
	effects = p_effects
	icon = p_icon
	tint = p_tint
