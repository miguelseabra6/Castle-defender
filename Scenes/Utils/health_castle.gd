extends Node
@export var hp : int
@export var max_hp : int
@export var health_bar : ProgressBar
@export var lost_label: Label
signal died

func take_damage(damage: int):

	hp = clamp(hp - (damage*2), 0, max_hp)
	
	# Update the progress bar
	update_health_bar()
  
	if hp <= 0:
		died.emit()
		on_lost()
# Update the progress bar to reflect the current health
func update_health_bar():
	if health_bar:
		health_bar.value = hp  # Set current value
	else:
		print("Health bar not assigned!")

func on_lost():
	# Show the "You lost" message
	if lost_label:
		lost_label.text = "The Wall went down. You Lost"
		lost_label.visible = true
	
	# Pause the game
	get_tree().paused = true
