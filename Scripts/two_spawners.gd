extends Node3D

var current_wave: int = 1
var active_waves: Dictionary = {}
var waves: Dictionary = {}
@export var wave_message_label: NodePath
signal wave_cleared(int)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var char_manager = get_parent().get_node("Player Units")
	wave_cleared.connect(char_manager._on_wave_cleared)




func _on_spawner_wave_cleared(wave_id: int) -> void:
	if waves.has(wave_id):
		waves[wave_id] += 1  # Increment the value if the key exists
	else:
		waves[wave_id] = 1  # Set the value to 1 if the key doesn't exist
	if waves[wave_id] >= 2:
		var wave_message = get_node(wave_message_label) as Label
		wave_message.text = "Wave %d Cleared!" % wave_id

		# Hide the message after a few seconds
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 2.0  # Adjust duration as needed
		timer.one_shot = true
		timer.start()
		timer.timeout.connect(self._hide_wave_message)




func _hide_wave_message():
	var wave_message = get_node(wave_message_label) as Label
	wave_message.text = ""
