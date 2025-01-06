extends CharacterBody3D
class_name Enemy

@export var speed = 3.5
@export var acceleration = 2.0
@export var area_min = Vector3(-5, 0, -5)  # Minimum corner of the walking area
@export var area_max = Vector3(0, 0, 0)   # Maximum corner of the walking 
@export var change_direction_interval = 2.0  # How often to change direction (in seconds)
@export var idle_chance = 0.3  # Chance to idle when changing direction (0.0 to 1.0)
@export var detection_range = 5.0 
@onready var anim_tree = $AnimationTree
@onready var state_machine = $AnimationTree["parameters/playback"]
@onready var model = $Rig
@export var attack_range = 2.0 
var is_attacking = false
var target_player = null
var direction = Vector3.ZERO
var time_since_last_change = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var helmet = get_node("Rig/Skeleton3D/Knight_Helmet/Knight_Helmet")

func _ready():
	direction = get_random_direction()
	
	var material = helmet.get_surface_override_material(0)  # Get the first material
	if not material:
		material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 0, 0) 
		helmet.set_surface_override_material(0, material)
		
	material.albedo_color = Color(1, 0, 0)  # Change the color to red
		
		
func get_random_direction() -> Vector3:
	if randf() < idle_chance:
		return Vector3.ZERO  # Idle
	# Generate a random target position within the bounds
	var random_x = randf_range(area_min.x, area_max.x)
	var random_z = randf_range(area_min.z, area_max.z)
	var target_position = Vector3(random_x, global_transform.origin.y, random_z)
	return (target_position - global_transform.origin).normalized()


func _physics_process(delta):
	velocity.y += -gravity * delta

	update_target_player()

	if target_player:
		move_towards_player(delta)
	else:
		idle_wander(delta)

	move_and_slide()

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

	if distance_to_player > attack_range:
		# Move towards the player
		velocity.x = direction_to_player.x * speed
		velocity.z = direction_to_player.z * speed

		# Rotate toward the player
		var target_rotation_y = atan2(direction_to_player.x, direction_to_player.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)

	else:
		# Stop and attack if within attack range
		velocity.x = 0
		velocity.z = 0
		if not is_attacking:
			attack()

func attack():
	is_attacking = true
	state_machine.travel("1h_melee_chop")
	var timer = Timer.new()
	timer.wait_time = 1.0  # Adjust based on the attack animation duration
	timer.one_shot = true
	timer.connect("timeout", _on_attack_finished)
	add_child(timer)
	timer.start()

func _on_attack_finished():
	is_attacking = false

var i = 0
func _on_knight_hurt(damage: int) -> void:
	$Health.take_damage(damage)
	i = i+ 1
	print(i)


func _on_health_died() -> void:

	print("dying")
	var timer = Timer.new()
	timer.wait_time = 0.8  # Set to the duration of the Death_A animation
	timer.one_shot = true
	timer.connect("timeout",_on_death_timer_finished)
	add_child(timer)
	timer.start()
	state_machine.travel("Death_A")

func _on_death_timer_finished() -> void:
	queue_free()
