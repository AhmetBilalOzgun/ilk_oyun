extends Resource
class_name Enemy

# Düşman tanımı (veri). weakness_effects: bu etkiyle vurulursa EKSTRA hasar.
# resist_effects: bu etkiyle vurulursa AZALTILMIŞ hasar (asla sıfır — bkz
# BattleDamage). skills: MVP eklentisi — spec'te Enemy'nin saldırısı tanımsızdı
# ama EnemyAI "en yüksek hasarlı saldırıyı seç" için bir saldırı listesi gerekir.
# Düşman QTE yapmaz; becerileri taban hasarla çözülür.
# Not: scripts/enemy.gd (eski gerçek-zamanlı Node davranışı) ile karıştırma —
# bu saf veri Resource'u, o Node. (Eski sistem deprecated/ altına taşındı.)

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 1
@export var speed: int = 0
@export var skills: Array[Skill] = []            # düşman saldırıları (EnemyAI seçer)
@export var weakness_effects: Array[String] = [] # bu etki -> ekstra hasar
@export var resist_effects: Array[String] = []   # bu etki -> azaltılmış hasar
