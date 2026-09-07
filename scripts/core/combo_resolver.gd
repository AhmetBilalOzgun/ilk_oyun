extends RefCounted
class_name ComboResolver

# Saf, yan etkisiz, deterministik büyü birleştirici.
# List<RuneId> + RuneDB -> ResolvedSpell. Motor/zaman/düşman bilmez.
#
# Kurallar (öncelik tabanlı — sonuç elle yazılmaz):
#   Taşıyıcı: komboda bulunan İLK rün taşıyıcılık kazanır.
#   Etki:     tüm rünlerin etkileri toplanır (strike'ın etkisi null → katkı yok),
#             sonra füzyon tablosu uygulanır. Eşleşme yoksa etkiler yan yana.
#             Zıt rünler iptal etmez — HER ZAMAN bir sonuç üretilir.
#   Hasar:    taban = ilk rünün base_damage'ı; her EK rün ×mult (çarpımsal).

static func resolve(rune_ids: Array, db: RuneDB) -> ResolvedSpell:
	var spell := ResolvedSpell.new()
	spell.rune_ids = rune_ids.duplicate()
	if rune_ids.is_empty():
		return spell

	var first: RuneDB.RuneDef = db.get_rune(rune_ids[0])
	if first == null:
		return spell
	spell.carrier = first.carrier

	# Etkileri sırayla topla (null atla, tekrarları önle).
	var effects: Array = []
	for id in rune_ids:
		var rd: RuneDB.RuneDef = db.get_rune(id)
		if rd != null and rd.effect != null and not effects.has(rd.effect):
			effects.append(rd.effect)

	spell.effects = _apply_fusions(effects, db, spell.fusion_notes)

	# Hasar: taban × mult^(ek rün sayısı). Çarpımsal.
	var dmg := float(first.base_damage)
	var extra := rune_ids.size() - 1
	for _i in range(extra):
		dmg *= db.combo_multiplier_per_rune
	spell.damage = int(round(dmg))
	return spell

# Füzyon tablosunu tekrar tekrar uygula: eşleşen ilk çifti tek sonuçla değiştir.
# Eşleşme kalmayınca dur. Deterministik (soldan sağa tarama).
static func _apply_fusions(effects: Array, db: RuneDB, notes: Array) -> Array:
	var result: Array = effects.duplicate()
	var changed := true
	while changed:
		changed = false
		for i in range(result.size()):
			for j in range(i + 1, result.size()):
				var fused := db.fusion_for(result[i], result[j])
				if fused != "":
					notes.append("%s+%s->%s" % [result[i], result[j], fused])
					var a = result[i]
					var b = result[j]
					result.remove_at(j)   # önce büyük indeksi çıkar
					result.remove_at(i)
					if not result.has(fused):
						result.append(fused)
					changed = true
					break
			if changed:
				break
	return result
