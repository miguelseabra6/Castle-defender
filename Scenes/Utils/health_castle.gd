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


func on_lost():
	# Show the "You lost" message
	if lost_label:
		lost_label.text = "The Wall went down. You Lost"
		lost_label.visible = true

	

	# Create a Timer dynamically
	var timer = Timer.new()
	timer.wait_time = 5  # Set the wait time to 10 seconds
	timer.one_shot = true  # Set the timer to one-shot mode

	# Connect the timeout signal to this script
	timer.connect("timeout", _on_Timer_timeout)

	# Add the timer as a child of the current node and start it
	add_child(timer)
	timer.start()

func _on_Timer_timeout():


	# Change to metu.tscn
	var menu_scene ="res://Scenes/UI/menu.tscn"
	get_tree().change_scene_to_file(menu_scene)
