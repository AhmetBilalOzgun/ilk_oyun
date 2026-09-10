extends IRuneRecognizer
class_name FakeRecognizer

# Testler + QTE prototipi için deterministik tanıyıcı. Ne çizildiğine bakmaz,
# önceden verilen sonucu döner. null -> QTE başarısız (fail-soft: taban hasar).
# Gerçek oyunda RecognizerAdapter (geometri) kullanılır; bu arayüzün yerini tutar.

var result  # rune_id (String) veya null

func _init(p_result = null) -> void:
	result = p_result

func recognize(_strokes) -> Variant:
	return result
