extends CharacterBody3D
class_name Enemy

@export var speed = 1.5
@export var acceleration = 2.0
@export var area_min = Vector3(-5, 0, -5)  # Minimum corner of the walking area
@export var area_max = Vector3(0, 0, 0)   # Maximum corner of the walking 
@export var change_direction_interval = 2.0  # How often to change direction (in seconds)
@export var idle_chance = 0.3  # Chance to idle when changing direction (0.0 to 1.0)

@onready var anim_tree = $AnimationTree
@onready var state_machine = $AnimationTree["parameters/playback"]
@onready var model = $Rig

var direction = Vector3.ZERO
var time_since_last_change = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	direction = get_random_direction()

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

	time_since_last_change += delta
	if time_since_last_change >= change_direction_interval:
		# Change direction after a certain interval
		direction = get_random_direction()
		time_since_last_change = 0.0

	# Apply movement in the current direction
	if direction != Vector3.ZERO:
		var vy = velocity.y
		velocity.y = 0
		velocity = lerp(velocity, direction * speed, acceleration * delta)
		velocity.y = vy

		# Smoothly rotate the model to face the movement direction
		var target_rotation_y = atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)

	# Update the animation tree based on movement
	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)

	move_and_slide()
	


var i = 0
func _on_knight_hurt(damage: Variant) -> void:
	print(damage)
	i = i+ 1
	print(i)
