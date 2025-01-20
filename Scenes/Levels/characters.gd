extends Node3D

@export var knight_scene: PackedScene = ResourceLoader.load("res://Scenes/Characters/knight.tscn")
@export var mage_scene: PackedScene = ResourceLoader.load("res://Scenes/Characters/mage.tscn")

# Current leader knight
var leader = null

# Enemy kill count
var enemy_kill_count: int = 0

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
	if leader is Mage:
		get_parent().get_node("TextureRect").visible = true
	else:
		get_parent().get_node("TextureRect").visible = false
		
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
	elif event.is_action_pressed("change_mage"):
		print("Changing leader to a Mage...")
		change_leader_to(Mage)
	elif event.is_action_pressed("change_knight"):
		print("Changing leader to a Knight...")
		change_leader_to(Knight)


# Change the leader to the next character of the specified type
func change_leader_to(target_type):
	var chars = null
	if target_type == Mage:
		chars = get_chars().filter(func(char):
			return char is Mage
		)
	elif target_type == Knight:
		chars = get_chars().filter(func(char):
			return char is Knight
		)

	if chars.size() == 0:
		print("No characters of type", target_type, "available.")
		return

	var current_index = chars.find(leader)
	var next_index = (current_index + 1) % chars.size()

	set_leader(chars[next_index])
	
	
	
# Change to the next sin the list
func change_leader():
	var chars = get_chars()
	if chars.size() <= 1:
		return  # Do nothing if only one knight remains

	var current_index = chars.find(leader)
	if current_index == -1:
		current_index = 0

	var next_index = (current_index + 1) % chars.size()

	# Skip any invalid knights
	while not is_instance_valid(chars[next_index]):
		next_index = (next_index + 1) % chars.size()

	set_leader(chars[next_index])

# Handle knight death
func _on_character_died(character):
	print("Someone died.", character)
	if character == leader:
		update_leader()
	if get_chars().size() <= 0:
		SceneHandler.go_to_menu()

# Update the leader knight
func update_leader():
	var chars = get_chars()
	if chars.size() > 0:
		var current_index = chars.find(leader)
		if current_index == -1:
			current_index = 0

		var next_index = (current_index + 1) % chars.size()

	# Skip any invalid knights
		while not is_instance_valid(chars[next_index]):
			next_index = (next_index + 1) % chars.size()

		set_leader(chars[next_index])
	else:
		leader = null
		print("No knights remaining.")

# Handle enemy death and spawn characters accordingly
func _on_enemy_died(enemy_type: String) -> void:
	enemy_kill_count += 1

	print("Enemy killed! Total kills:", enemy_kill_count)

	if enemy_kill_count % 8 == 0:
		spawn_mage()
	elif enemy_kill_count % 4 == 0:
		spawn_knight()

# Spawn a knight
func spawn_knight():
	if knight_scene:
		print("Spawning knight...")
		var new_knight = knight_scene.instantiate()
		add_child(new_knight)
		# Position the knight near the leader
		if leader:
			new_knight.global_transform.origin = leader.model.global_position + Vector3(1, 0, 1)
		

		leader.get_node("SpringArm3D").get_node("Camera3D").make_current()
	else:
		print("Knight scene not assigned!")

# Spawn a mage
func spawn_mage():
	if mage_scene:
		print("Spawning mage...")
		var new_mage = mage_scene.instantiate()
		add_child(new_mage)
		# Position the mage near the leader
		if leader:
			new_mage.global_transform = Transform3D(leader.global_transform.basis, leader.global_transform.origin + Vector3(2, 0, 2))
		

		leader.get_node("SpringArm3D").get_node("Camera3D").make_current()
	else:
		print("Mage scene not assigned!")
