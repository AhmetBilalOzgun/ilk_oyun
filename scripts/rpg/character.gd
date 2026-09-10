extends Resource
class_name Character

# Parti üyesi tanımı (veri). speed tur sırasını belirler (yüksek önce).
# skills bir menüde listelenir; oyuncu birini seçince QTE tetiklenir.
# Saf veri: Node/Engine/zaman bilmez.

@export var id: String = ""
@export var display_name: String = ""
@export var element_pair: Array[String] = []   # örn. ["Yıldırım", "Ateş"]
@export var max_hp: int = 1
@export var speed: int = 0                      # tur sırası (yüksek = önce)
@export var skills: Array[Skill] = []
