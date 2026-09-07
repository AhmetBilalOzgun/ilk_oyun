extends RefCounted
class_name ResolvedSpell

# ComboResolver'ın saf çıktısı. Motor/düşman bilmez — sadece büyünün kimliği.

var carrier: String = ""          # taşıyıcı: komboda ilk rünün carrier'ı
var effects: Array = []           # uygulanan etkiler (füzyon sonrası)
var damage: int = 0               # çözülmüş hasar (weakness/overdrive HARİÇ)
var fusion_notes: Array = []      # ["Burn+Freeze->Steam", ...]
var rune_ids: Array = []          # kaynak rünler (debug/overlay)

func describe() -> String:
	var eff := "yok" if effects.is_empty() else ", ".join(effects)
	return "%s | %s | %d hasar" % [carrier, eff, damage]
