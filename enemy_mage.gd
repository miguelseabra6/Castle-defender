extends CharacterBody3D
class_name Enemy_mage

@export var speed = 3.5
@export var acceleration = 2.0
@onready var spawn = global_position
@export var spell_scene : PackedScene  = ResourceLoader.load("res://Scenes/Utils/enemy_spell.tscn")

@onready var area_min = spawn + Vector3(-5, 0, -5)  # Minimum corner of the walking area
@onready var area_max = spawn + Vector3(0, 0, 0)   # Maximum corner of the walking 
@export var change_direction_interval = 2.0  # How often to change direction (in seconds)
@export var idle_chance = 0.3  # Chance to idle when changing direction (0.0 to 1.0)
@export var detection_range = 20.0 
@onready var anim_tree = $AnimationTree
@onready var state_machine = $AnimationTree["parameters/playback"]
@onready var model = $Rig
@export var attack_range = 10.0 
var is_attacking = false
var target_player = null
var direction = Vector3.ZERO
var time_since_last_change = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var retreat_health_threshold: int = 30
@onready var helmet = get_node("Rig/Skeleton3D/Mage_Hat/Mage_Hat")
@export var rotation_speed = 12.0
var safe_spot : Vector3

func _ready():
	safe_spot = global_transform.origin

	
	var material = helmet.get_surface_override_material(0)  # Get the first material
	if not material:
		material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 0, 0) 
		helmet.set_surface_override_material(0, material)
		
	material.albedo_color = Color(1, 0, 0)  # Change the color to red

	
func _physics_process(delta):
	# Apply gravity
	velocity.y += -gravity * delta

	# Update wandering behavior periodically
	time_since_last_change += delta
	if time_since_last_change >= change_direction_interval:
		idle_wander()
		time_since_last_change = 0.0

	# Check for health to decide between retreat or attack/follow
	if $Health.hp < retreat_health_threshold:
		retreat_to_safe_spot(delta)
	elif target_player:
		# If the player is within attack range, attack
		if global_transform.origin.distance_to(target_player.global_transform.origin) <= attack_range:
			attack()
		else:
			# Follow the target player
			follow_target(delta)
	else:
		# If no target, search for one
		search_for_target()

	# Move the character using Godot's built-in physics
	move_and_slide()

# Updated idle wandering behavior
func idle_wander():
	if randf() < idle_chance:
		# Chance to idle (stop moving)
		direction = Vector3.ZERO
	else:
		# Move in a random direction within bounds
		var random_direction = Vector3(
			randf_range(-1, 1),
			0,
			randf_range(-1, 1)
		).normalized()

		var target_position = global_position + random_direction * speed * change_direction_interval
		target_position.x = clamp(target_position.x, area_min.x, area_max.x)
		target_position.z = clamp(target_position.z, area_min.z, area_max.z)

		direction = (target_position - global_position).normalized() * speed

	# Update velocity
	velocity.x = direction.x
	velocity.z = direction.z

# Search for the nearest target
func search_for_target():
	var player_units = get_parent().get_parent().get_node("Player Units").get_children()
	var closest_distance = detection_range
	target_player = null

	for player in player_units:
		var distance = global_transform.origin.distance_to(player.global_transform.origin)
		if distance < closest_distance:
			closest_distance = distance
			target_player = player

# Follow the target player
# Updated follow_target function for smoother movement
func follow_target(delta):
	if target_player:
		var direction_to_target = (target_player.global_transform.origin - global_transform.origin).normalized()
		velocity.x = lerp(velocity.x, direction_to_target.x * speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction_to_target.z * speed, acceleration * delta)



	
# Attack the target player
func attack():
	if not is_attacking:
		is_attacking = true
		state_machine.travel("Spellcast_Shoot")

		var spell :  = spell_scene.instantiate()



		owner.add_child(spell)
		spell.global_position = global_position + Vector3(0, 1.5, 1)  # Offset to spawn in front of the camera
		print(target_player.global_transform.origin)
		var direction = (target_player.global_transform.origin - spell.global_position).normalized()
		spell.set("direction", direction)
	

		var attack_timer = Timer.new()
		attack_timer.wait_time = 1.0
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_finished)
		add_child(attack_timer)
		attack_timer.start()

func _on_attack_finished():
	is_attacking = false

# Retreat to a safe spot
func retreat_to_safe_spot(delta):
	var direction_to_safe_spot = (safe_spot - global_transform.origin).normalized()
	velocity.x = direction_to_safe_spot.x * speed
	velocity.z = direction_to_safe_spot.z * speed

	rotate_toward_safe_spot()

# Rotate toward the safe spot
func rotate_toward_safe_spot():
	var target_rotation_y = atan2(safe_spot.x - global_transform.origin.x, safe_spot.z - global_transform.origin.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, rotation_speed * get_process_delta_time())





var i = 0
func _on_hurt(damage: int) -> void:
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
