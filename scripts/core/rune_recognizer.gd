extends RefCounted
class_name IRuneRecognizer

# Rün tanıma sözleşmesi. Motor tarafı adaptör bunu uygular (geometri main.gd'de).
# recognize(strokes) -> rune_id (String) VEYA null.
# null → çağıran taraf STRIKE'a düşer. Sistem asla "anlaşılmadı" üretmez.
# Çekirdek state machine geometriyi bilmesin diye tanıma ADAPTÖRDE yapılır ve
# sonuç (rune_id | null) sm.on_finger_up()'a verilir — sm saf/headless kalır.

func recognize(_strokes) -> Variant:
	return null
