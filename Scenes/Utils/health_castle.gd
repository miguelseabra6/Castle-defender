extends Node
@export var hp : int
@export var max_hp : int
@export var health_bar : ProgressBar
signal died

func take_damage(damage: int):

	hp = clamp(hp - damage, 0, max_hp)
	
	# Update the progress bar
	update_health_bar()
  
	if hp <= 0:
		died.emit()

# Update the progress bar to reflect the current health
func update_health_bar():
	if health_bar:
		health_bar.value = hp  # Set current value
	else:
		print("Health bar not assigned!")
