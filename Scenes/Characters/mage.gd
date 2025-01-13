extends CharacterBody3D
class_name Mage

@export var spell_scene : PackedScene  = ResourceLoader.load("res://Scenes/Utils/spell.tscn")
@export var spell_slow : PackedScene  = ResourceLoader.load("res://Scenes/Utils/spell_slow.tscn")
@export var spell_vulnerable : PackedScene  = ResourceLoader.load("res://Scenes/Utils/spell_vulnerable.tscn")
@export var speed = 6.0
@export var acceleration = 4.0
@export var jump_speed = 8.0


var jumping = false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var model = $Rig
@onready var anim_tree  = $AnimationTree
@onready var spring_arm = null

@onready var state_machine = $AnimationTree["parameters/playback"]
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var mouse_sensitivity = 0.0025
@export var rotation_speed = 12.0
var last_floor = true
var attacks = [
	"1H_Melee_Attack_Slice_Diagonal",
	"1h_melee_chop",
]
	
var leader_knight = null
@export var is_leader = false

var is_attacking = false
signal changed
signal changed_other
var player_units = null
var self_index = self.get_index()
func _ready():
	died.connect(get_parent()._on_character_died)
	player_units = get_parent().get_children()


	if not is_leader:
		for child in get_parent().get_children():
			if child.is_leader:
				leader_knight = child
				spring_arm = child.get_node("SpringArm3D")
				ray_cast  = child.get_node("SpringArm3D/Camera3D/RayCast3D")
		
	else:
		spring_arm = $SpringArm3D
		spring_arm.get_node("Camera3D").make_current()
	anim_tree.set("parameters/Block/playback_speed", -1.0)
	

var block_animation = "Block"
var blocking_animation = "Blocking"
var reverse_block_animation = "Block 2"


@warning_ignore("shadowed_variable")
func get_attack_duration(attack: String) -> float:
	# Define durations for each attack type
	match attack:
		"1h_melee_chop": return 1.0667
		"1H_Melee_Attack_Slice_Diagonal": return 1
		_: return 1
var is_blocking = false

signal hit
@onready var camera = $SpringArm3D/Camera3D
@onready var ray_cast = $SpringArm3D/Camera3D/RayCast3D
@export var bullet_speed = 50.0
@export var min_length: float = 2.0  # Minimum zoom distance
@export var max_length: float = 50.0  # Maximum zoom distance
func _unhandled_input(event):
	if is_leader:
		if event is InputEventMouseMotion:
			spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
			spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90.0, 30.0)
			spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
		elif event.is_action_pressed("attack"):
			play_attack_animation()
			attack(spell_scene)
		elif event.is_action_pressed("spell_slow"):
			attack_slow()
		elif event.is_action_pressed("spell_vulnerable"):
			attack_vulnerable()
		elif event.is_action_pressed("zoom_in"):
			spring_arm.spring_length = clamp(spring_arm.spring_length - 1, min_length, max_length)

		elif event.is_action_pressed("zoom_out"):
			spring_arm.spring_length = clamp(spring_arm.spring_length + 1, min_length, max_length)

			
			
		


func get_move_input(delta):
	var vy = velocity.y

	var input = Input.get_vector("left", "right","forward","backwards")
	var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	velocity = lerp(velocity, dir * speed, acceleration * delta)
	velocity.y = vy
	velocity = lerp(velocity, dir * speed, acceleration * delta)
	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
		jumping = true
		anim_tree.set("parameters/conditions/grounded", false)
		anim_tree.set("parameters/conditions/jumping", true)
	# We just hit the floor after being in the air
	if is_on_floor() and not last_floor:
		jumping = false
		anim_tree.set("parameters/conditions/jumping", false)
		anim_tree.set("parameters/conditions/grounded", true)
	
	if not is_on_floor() and not jumping:
		state_machine.travel("Jump_Idle")
		anim_tree.set("parameters/conditions/grounded", false)
	last_floor = is_on_floor()
	
@export var horizontal_offset = 3.0  # Spread between mages
@export var follow_distance = 10.0  # Distance behind the leader

@export var move_speed = 4.0  # Movement speed for the mage



func get_leader_rotation():
	if leader_knight.velocity.length() > 0:
		var direction = leader_knight.velocity.normalized()
		var rotation_y = atan2(direction.x, direction.z)
		return Vector3(0, rad_to_deg(rotation_y), 0)
	return leader_knight.get_rotation_degrees()
	
func follow_leader(delta):
	var knights = []
	for child in get_parent().get_children():
		if child is Knight:
			knights.append(child)


	if knights.size() > 0:
		# Calculate the center point of all knights
		var average_position = Vector3.ZERO
		var average_direction = Vector3.ZERO

		for knight in knights:
			average_position += knight.global_transform.origin
			var knight_rotation_y = knight.model.rotation.y
			average_direction += Vector3(sin(knight_rotation_y), 0, cos(knight_rotation_y)).normalized()

		average_position /= knights.size()
		average_direction = average_direction.normalized()

		# Only follow if the group is moving
		var is_group_moving = leader_knight.velocity.length() > 1.0

		if is_group_moving:
			# Formation settings
			var row_spacing = 2.5
			var column_spacing = 2.5

			# Get this mage's position in the formation
			var index = get_parent().get_children().find(self)
			var row = index / 3
			var column = index % 3

			# Calculate the target position behind the group of knights
			var target_position = average_position
			target_position -= average_direction * (row + 1) * row_spacing  # Move rows back
			target_position += Vector3(-average_direction.z, 0, average_direction.x) * (column - 1.5) * column_spacing  # Spread columns sideways

			# Move toward the target position
			var move_direction = (target_position - global_transform.origin).normalized()
			var distance_to_target = global_transform.origin.distance_to(target_position)
			var slow_factor = clamp(distance_to_target / row_spacing, 0.0, 1.0)

			velocity.x = move_direction.x * speed * slow_factor
			velocity.z = move_direction.z * speed * slow_factor

			# Smoothly rotate toward the movement direction
			if velocity.length() > 1.0:
		  # Get the forward direction of the leader's model
				var leader_forward = leader_knight.model.global_transform.basis.z.normalized()

		# Smoothly rotate the follower to align with the leader's forward direction
				var current_forward = model.global_transform.basis.z.normalized()  # Forward vector of the follower model
				var target_rotation_y = atan2(leader_forward.x, leader_forward.z)  # Target rotation based on leader's forward
				var current_rotation_y = atan2(current_forward.x, current_forward.z)  # Current rotation

				model.rotation.y = lerp_angle(current_rotation_y, target_rotation_y, rotation_speed * delta)
		else:
			velocity.x = 0
			velocity.z = 0
	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)



func _physics_process(delta):
	velocity.y += -gravity * delta
	if is_leader:
		# Standard control logic for the leader knight
		
		get_move_input(delta)
		move_and_slide()
		
	else:
		# Follower logic for the knight
		follow_leader(delta)
		move_and_slide()
		
	if velocity.length() > 1.0:
		var adjusted_rotation_y = spring_arm.rotation.y + PI
		model.rotation.y = lerp_angle(model.rotation.y, adjusted_rotation_y, rotation_speed * delta)


func attack(spell:PackedScene):
	var new_spell = null
	if spell == spell_scene:
		new_spell  = spell_scene.instantiate()
	elif spell == spell_slow:
		new_spell = spell_slow.instantiate()
	elif spell == spell_vulnerable:
		new_spell = spell_vulnerable.instantiate()
	get_tree().root.add_child(new_spell)
	var tip = get_node("Rig/Skeleton3D/2H_Staff/tip")
	new_spell.global_position = tip.global_position # Offset to spawn in front of the camera
 
# Get the forward direction of the camera
	ray_cast.target_position = Vector3(0, 0, 100)
	if ray_cast.is_colliding():
# Get the collision point
		var collision_point = ray_cast.get_collision_point()
# Get the object that was hit
		var hit_object = ray_cast.get_collider()
# Set the spell's movement direction toward the collision point
		var direction = (collision_point - new_spell.global_position).normalized()
		new_spell.set("direction", direction)  # Pass the direction to the spell
	else:
	# Get the direction the spring_arm is pointing
		var direction = -spring_arm.global_transform.basis.z.normalized()
	# Calculate the target position 50 meters away in the direction of the spring_arm
		var target_position = spring_arm.global_position + (direction * 50)
	# Calculate a direction vector from the spell's position to the target position
		var adjusted_direction = (target_position - new_spell.global_position).normalized()
		new_spell.set("direction", adjusted_direction)  # Pass the direction to the spell

func play_attack_animation():
	if not is_attacking:
		state_machine.travel("Spellcast_Shoot")
		is_attacking = true
		var attack_timer = Timer.new()
		attack_timer.wait_time = 1.0
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_finished)
		add_child(attack_timer)
		attack_timer.start()

func _on_attack_finished():
	is_attacking = false
		
		
func attack_slow():
	if not is_attacking:
		state_machine.travel("Spellcast_Shoot")
		is_attacking = true
		var attack_timer = Timer.new()
		attack_timer.wait_time = 1.0
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_finished)
		add_child(attack_timer)
		attack_timer.start()
		attack(spell_slow)

func attack_vulnerable():
	if not is_attacking:
		state_machine.travel("Spellcast_Shoot")
		is_attacking = true
		var attack_timer = Timer.new()
		attack_timer.wait_time = 1.0
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_finished)
		add_child(attack_timer)
		attack_timer.start()
		attack(spell_vulnerable)
func _on_changed() -> void:

		is_leader = true
		spring_arm = $SpringArm3D
		$SpringArm3D/Camera3D.make_current()
		ray_cast = get_node("SpringArm3D/Camera3D/RayCast3D")
		



func _on_changed_other() -> void:
	for child in get_parent().get_children():
		if child.is_leader:
			leader_knight = child
			spring_arm = child.get_node("SpringArm3D")
			ray_cast = child.get_node("SpringArm3D/Camera3D/RayCast3D")
	
	is_leader= false
	




signal hurt(int)
var damage_amount = 5

	
func _on_sword_area_entered(body : Area3D) -> void:


	if body.is_in_group("hurt_boxes"):
		hurt.emit(5)

func _on_hurt(damage: int) -> void:
	$Health.take_damage(damage)


signal died(character)
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
	died.emit(self)
	queue_free()
	
