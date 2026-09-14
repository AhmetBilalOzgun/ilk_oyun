extends Resource
class_name InputSequence

# Bir becerinin AKTİF GİRDİ dizisi (veri). Çizim YOK — kısa dokun/kaydır dizisi.
# Her form/beceri kendi dizisini tanımlar (ör. Kor: SOL->SAĞ->DOKUN). Saf veri:
# Node/Engine/geometri BİLMEZ. Ekran jestini yakalayıp bu adımlara çeviren katman
# sunumda (bkz battle.gd). Değerlendirme InputEvaluator'da (saf) yapılır.
#
# window: tüm diziyi MÜKEMMEL saymak için toplam süre bütçesi (sn). Aşılırsa (ama
# dizi doğruysa) sonuç İYİ'ye düşer — fail-soft. <=0 -> zamanlama yok sayılır.

enum Step { TAP, SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN }

@export var steps: Array = []           # Step değerleri (int), sırayla
@export var window: float = 1.4         # sn; içinde tamamlanırsa MÜKEMMEL

func _init(p_steps: Array = [], p_window: float = 1.4) -> void:
	steps = p_steps
	window = p_window

func size() -> int:
	return steps.size()

# Adımların insan-okur kısa etiketi (UI ipucu için).
static func step_label(step: int) -> String:
	match step:
		Step.TAP: return "●"
		Step.SWIPE_LEFT: return "◀"
		Step.SWIPE_RIGHT: return "▶"
		Step.SWIPE_UP: return "▲"
		Step.SWIPE_DOWN: return "▼"
	return "?"

func hint() -> String:
	var parts: Array = []
	for s in steps:
		parts.append(step_label(s))
	return " → ".join(parts)
