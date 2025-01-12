extends Node3D

@export var knight_scene: PackedScene = ResourceLoader.load("res://Scenes/Characters/knight.tscn")
@export var mage_scene: PackedScene = ResourceLoader.load("res://Scenes/Characters/mage.tscn")

# Current leader knight
var leader = null

# Called when the scene is ready
func _ready() -> void:
	var chars = get_chars()
	if chars.size() > 0:
		set_leader(chars[0])
	else:
		leader = null
		print("No knights remaining.")



# Set a new leader knight
func set_leader(new_leader):
	if leader and is_instance_valid(leader):
		leader.is_leader = false

	leader = new_leader
	leader.is_leader = true
	leader._on_changed()

	for child in get_children():
		if child != leader and is_instance_valid(child):
			child._on_changed_other()

	print("New leader is:", leader.name)

# Get all alive knights
func get_chars() -> Array:
	return get_children().filter(func(char):
		return is_instance_valid(char)
	)

# Handle leader change input
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("change"):
		print("Leader change requested.")
		change_leader()

# Change to the next knight in the list
func change_leader():
	var chars = get_chars()
	if chars.size() <= 1:
		return  # Do nothing if only one knight remains

	var current_index = chars.find(leader)
	if current_index == -1:
		current_index = 0

		# Find the next valid knight
	var next_index = (current_index + 1) % chars.size()

	# Skip any invalid knights
	while not is_instance_valid(chars[next_index]):
		next_index = (next_index + 1) % chars.size()

	set_leader(chars[next_index])

# Handle knight death
func _on_character_died(character):
	print("Someone died.",character)
	if character == leader:
		update_leader()

# Update the leader knight
func update_leader():
	var chars = get_chars()
	if chars.size() > 0:
		var index = chars.find(leader) + 1
		print(index)
		while not is_instance_valid(chars[index]):
			index = (index + 1) % chars.size()
			print(index)
		set_leader(chars[index])
	else:
		leader = null
		print("No knights remaining.")


func _on_enemy_died(enemy_type: String) -> void:
	if enemy_type == "Knight":
		if knight_scene:
			print("Trying to spawn knight...")

			# Instantiate the knight
			var new_knight = knight_scene.instantiate()

			# Position the new knight next to the current leader
			if leader:
				new_knight.global_transform = Transform3D(leader.global_transform.basis, leader.global_transform.origin + Vector3(2, 0, 2))  # Adjust position
			# Add the knight to the scene
			add_child(new_knight)
			leader.get_node("SpringArm3D").get_node("Camera3D").make_current()
		else:
			print("Knight scene not assigned!")
	elif enemy_type == "Mage":
		if mage_scene:
			print("Trying to spawn mage...")
			# Instantiate the knight
			var new_mage = mage_scene.instantiate()
			# Position the new knight next to the current leader
			if leader:
				new_mage.global_transform = Transform3D(leader.global_transform.basis, leader.global_transform.origin + Vector3(2, 0, 2))  # Adjust position
			# Add the knight to the scene
			add_child(new_mage)
			leader.get_node("SpringArm3D").get_node("Camera3D").make_current()
		else:
			print("Knight scene not assigned!")
