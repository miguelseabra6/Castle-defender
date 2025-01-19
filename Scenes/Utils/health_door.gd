extends Node
@export var hp : int
@export var max_hp : int
@export var health_bar : ProgressBar
signal died

func take_damage(damage : int):
	print("door hit")
	hp = clamp(hp - damage, 0, max_hp)
	if hp <= 0:
		died.emit()
