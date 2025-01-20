extends CharacterBody3D
class_name Invading_Knight

@export var speed = 4
@export var acceleration = 2.0
@onready var spawn = global_position
@onready var area_min = spawn + Vector3(-5, 0, -5)  # Minimum corner of the walking area
@onready var area_max = spawn + Vector3(0, 0, 0)   # Maximum corner of the walking area
@export var change_direction_interval = 2.0  # How often to change direction (in seconds)
@export var idle_chance = 0.3  # Chance to idle when changing direction (0.0 to 1.0)
@export var detection_range = 4.0
@onready var anim_tree = $AnimationTree
@onready var state_machine = $AnimationTree["parameters/playback"]
@onready var model = $Rig
@export var attack_range = 2.0
@onready var vulnerable = false
@onready var helmet = get_node("Rig/Skeleton3D/Knight_Helmet/Knight_Helmet")
@onready var castle_script = get_parent().get_parent().get_node("castle")
var is_attacking = false
var target_player = null
var direction = Vector3.ZERO
var time_since_last_change = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var attack_in_progress = false
var target_door = null
var target = null
signal died(String)

# List of attack animations
var attacks = [
	"1H_Melee_Attack_Slice_Diagonal",
	"1h_melee_chop",
	"1H_Melee_Attack_Slice_Horizontal",
]

func _ready():
	direction = get_random_direction()
	var char_manager = get_parent().get_parent().get_node("Player Units")
	died.connect(char_manager._on_enemy_died)
	# Change the helmet color to red
	var material = helmet.get_surface_override_material(0)
	if not material:
		material = StandardMaterial3D.new()
		helmet.set_surface_override_material(0, material)
	material.albedo_color = Color(1, 0, 0)

func _physics_process(delta):
	# Apply gravity
	velocity.y += -gravity * delta

	# Update targets
	update_target_player()
	update_target_door()

	if target_player:
		# Calculate distance to player
		var distance_to_player = global_transform.origin.distance_to(target_player.global_transform.origin)
		
		if distance_to_player <= 5.0:
			# Move toward player if within 5 units
			attacking_wall = false
			move_towards_player(delta)
		else:
			# Move toward door otherwise
			move_towards_door(delta)
	else:
		# No player in range, move toward the door
		move_straight(delta)
	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	# Move character
	move_and_slide()



@onready var raycast = $RayCast3D
var attacking_wall = false
var avoiding = false  # Track if the knight is currently avoiding

func move_straight(delta):
	# Check if attacking
	if attack_in_progress:
		velocity.x = 0
		velocity.z = 0
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
		return

	# If avoiding, maintain the sideways movement
	if avoiding:
		velocity.z = 0  # Stop forward movement
	else:
		velocity.z = -speed  # Move forward

	# Check for obstacles using RayCast3D
	if raycast.is_colliding() and not avoiding:
		var collider = raycast.get_collider()
		if collider.is_in_group("enemy_knights"):  # Detect other enemies
			# Start avoidance
			avoiding = true
			velocity.x = speed  # Move to the side
			var timer = Timer.new()
			timer.wait_time = 3.0
			timer.one_shot = true
			timer.connect("timeout", _on_avoid_timer_finished)
			add_child(timer)
			timer.start()

	# Update animation for movement
	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	
	# Rotate model to face forward
	if not avoiding:
		var target_rotation_y = atan2(0, -1)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)
		

	# Check for collision with a wall
	if is_on_wall() and not avoiding:
		velocity.z = 0
		vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
		if not attack_in_progress:
			attack_wall()


func rotate_model_towards_direction(direction: Vector3, delta: float):
	if direction != Vector3.ZERO:
		var target_rotation_y = atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)

func _on_avoid_timer_finished():
	# Stop avoiding
	avoiding = false
	velocity.x = 0  # Stop sideways movement
func avoid_obstacle(delta):
	# Adjust velocity to move around the obstacle
	# Choose a side to move toward, e.g., left or right
	var side_step = global_transform.basis.x * (speed * 0.5)  # Step sideways

	# Randomly pick left or right if not previously decided
	if randf() < 0.5:
		velocity += side_step  # Move right
	else:
		velocity -= side_step  # Move left

	# Adjust rotation to face the new direction
	
	

func update_target_door():
	# Get all doors
	var castle = get_parent().get_parent().get_node("castle").get_children()
	var markers = []

	for marker in castle:
		if marker is Marker3D:
			markers.append(marker)
	# Initialize variables to track the closest door
	var closest_distance = null
	var closest_marker = null
	
	# Position of the current object (e.g., character or player)
	var current_position = global_transform.origin
	
	# Iterate through the doors to find the closest one
	for marker in markers:
	
		# Ensure the door is a valid Node3D with a global position
	
		var marker_position = marker.global_transform.origin
		var distance = current_position.distance_to(marker_position)
			
			# Update the closest door and distance if necessary
		if (closest_distance == null or distance < closest_distance):
			closest_distance = distance
			closest_marker = marker

	# Set the target_door to the closest door
	target_door = closest_marker

	

func move_towards_door(delta):

	var door_pos = target_door.global_transform.origin
	var direction_to_door = (door_pos - global_transform.origin).normalized()
	var distance_to_door = global_transform.origin.distance_to(door_pos)
	target = target_door
	if distance_to_door > attack_range:
		velocity.x = direction_to_door.x * speed
		velocity.z = direction_to_door.z * speed

		var target_rotation_y = atan2(direction_to_door.x, direction_to_door.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)

		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	else:
		# Stop and attack if within attack range
		velocity.x = 0
		velocity.z = 0
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
		if not attack_in_progress:
			attack()



func update_target_player():
	var player_units = get_parent().get_parent().get_node("Player Units").get_children()
	var closest_distance = detection_range
	target_player = null

	for player in player_units:
		var distance = global_transform.origin.distance_to(player.global_transform.origin)
		if distance < closest_distance:
			closest_distance = distance
			target_player = player

func idle_wander(delta):


	time_since_last_change += delta
	if time_since_last_change >= change_direction_interval:
		direction = get_random_direction()
		time_since_last_change = 0.0

	if direction != Vector3.ZERO:
		var vy = velocity.y
		velocity.y = 0
		velocity = lerp(velocity, direction * speed, acceleration * delta)
		velocity.y = vy

		var target_rotation_y = atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)

	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)

func move_towards_player(delta):

	var player_pos = target_player.global_transform.origin
	var direction_to_player = (player_pos - global_transform.origin).normalized()
	var distance_to_player = global_transform.origin.distance_to(player_pos)
	target = target_player
	if distance_to_player > attack_range:
		velocity.x = direction_to_player.x * speed
		velocity.z = direction_to_player.z * speed

		var target_rotation_y = atan2(direction_to_player.x, direction_to_player.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)

		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	else:
		# Stop and attack if within attack range
		velocity.x = 0
		velocity.z = 0
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
		if not attack_in_progress:
			attack()

func get_random_direction() -> Vector3:
	if randf() < idle_chance:
		return Vector3.ZERO  # Idle
	var random_x = randf_range(area_min.x, area_max.x)
	var random_z = randf_range(area_min.z, area_max.z)
	var target_position = Vector3(random_x, global_transform.origin.y, random_z)
	return (target_position - global_transform.origin).normalized()


func attack():

	var random_attack = attacks.pick_random()

	# Lock into attack animation
	var direction_to_target = (target.global_transform.origin - global_transform.origin).normalized()
	rotate_model_towards_direction(direction_to_target, get_process_delta_time())

	# Set up a timer to finish the attack
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.connect("timeout", _on_attack_finished)
	add_child(timer)
	timer.start()
	state_machine.travel(random_attack)


func attack_wall():

	var random_attack = attacks.pick_random()
	var direction_to_target = Vector3(0,0,1)
	rotate_model_towards_direction(direction_to_target, get_process_delta_time())
	
	# Set up a timer to finish the attack
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.connect("timeout", _on_attack_finished)
	add_child(timer)
	timer.start()
	state_machine.travel(random_attack)
	
func get_attack_duration(attack: String) -> float:
	match attack:
		"1h_melee_chop": return 1.0667
		"1H_Melee_Attack_Slice_Diagonal": return 1.0
		"1H_Melee_Attack_Slice_Horizontal": return 1.0667
		_: return 1.0

func _on_attack_finished():
	attack_in_progress = false

func _on_hurt(damage: int) -> void:
	if !vulnerable :
		$Health.take_damage(damage)
	else:
		$Health.take_damage(damage * 2)


func _on_vulnerable():
	vulnerable = true
func _on_slow():
	speed = 2
	var timer = Timer.new()
	timer.wait_time = 10
	timer.one_shot = true
	timer.connect("timeout", _on_slow_timer_finished)
	add_child(timer)
	timer.start()

func _on_slow_timer_finished():
	speed = 3.5
	
	
func _on_health_died() -> void:
	print("dying")
	var timer = Timer.new()
	timer.wait_time = 0.8
	timer.one_shot = true
	timer.connect("timeout", _on_death_timer_finished)
	add_child(timer)
	timer.start()
	state_machine.travel("Death_A")

func _on_death_timer_finished() -> void:
	queue_free()
	died.emit("Knight")

func _on_sword_area_entered(body: Area3D) -> void:
	if attack_in_progress:
		return

	attack_in_progress = true
	if (avoiding == true):
		if body.is_in_group("target_points"):
			print("attacked castle")
		
	if body.is_in_group("player_hurt_boxes"):
		var player = body.get_parent()

		# Calculate attack direction
		var attack_direction = (player.global_transform.origin - global_transform.origin).normalized()

		# Knight's forward direction based on the model's rotation
		var knight_forward = Vector3(sin(model.rotation.y), 0, cos(model.rotation.y)).normalized()

		# Calculate dot product to check if the attack is coming from the front
		var dot_product = knight_forward.dot(attack_direction)

		# If blocking and the attack is from the front, block the attack
		if player.is_blocking and dot_product > 0.5:
			print("Player blocked the attack!")
		else:
			print("Player hit!")
			player._on_hurt(5)


func _on_sword_body_entered(body: Node3D) -> void:

	if body.is_in_group("target_points"):

		body._on_hurt(5)
