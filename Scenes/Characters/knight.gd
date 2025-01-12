extends CharacterBody3D
class_name Knight

@export var speed = 5.0
@export var acceleration = 4.0
@export var jump_speed = 8.0

@export var knight_scene: PackedScene = ResourceLoader.load("res://Scenes/Characters/knight.tscn")

var jumping = false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var model = $Rig
@onready var anim_tree  = $AnimationTree
@onready var spring_arm = null

@onready var state_machine = $AnimationTree["parameters/playback"]
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var mouse_sensitivity = 0.0030
@export var rotation_speed = 12.0
var last_floor = true
var attacks = [
	"1H_Melee_Attack_Slice_Diagonal",
	"1h_melee_chop",
	"1H_Melee_Attack_Slice_Horizontal",
]
	
var leader_knight = null
@export var is_leader = false

var is_attacking = false 
signal changed()
signal changed_other

var player_units = null
var self_index = self.get_index()

func _ready():
	$AnimationPlayer.connect("animation_finished", _on_attack_animation_finished)
	died.connect(get_parent()._on_character_died)
	player_units = get_parent().get_children()
	for child in get_parent().get_parent().get_parent().get_node("Enemies").get_children():
			if child.is_in_group("enemies"):
				hurt.connect(child._on_hurt)
	
		
	
	if not is_leader:
		for child in get_parent().get_children():
			if child.is_leader:
				leader_knight = child
				spring_arm = child.get_node("SpringArm3D")
		
	else:
		print("lwader")
		spring_arm = $SpringArm3D
		$SpringArm3D/Camera3D.make_current()



var block_animation = "Block"
var blocking_animation = "Blocking"
var reverse_block_animation = "Block 2"

# Custom comparison function to sort by the scene tree index
func _compare_by_index(a, b):
	return a.get_index() - b.get_index()

@warning_ignore("shadowed_variable")
func get_attack_duration(attack: String) -> float:
	# Define durations for each attack type
	match attack:
		"1h_melee_chop": return 1.0667
		"1H_Melee_Attack_Slice_Diagonal": return 1
		"1H_Melee_Attack_Slice_Horizontal": return 1.0667
		_: return 1
		
		
var is_blocking = false

func _unhandled_input(event):
	if not is_leader:
		return

	if is_leader:
		if event is InputEventMouseMotion:
			spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
			spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90.0, 30.0)
			spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
		
		if event.is_action_pressed("attack"):
			print("attack")
			attack_enemy()
	if event.is_action_pressed("block"):
		print(self.get_index())
		print(is_leader)
		print(changed.get_connections())
		print(changed_other.get_connections())
		#if not is_blocking:
			## Start blocking (Play the 'Block' animation once)
			#state_machine.travel(block_animation)
			#is_blocking = true
			## After the block animation ends, transition to the "Blocking" state (looping)
			#state_machine.travel(blocking_animation)
	#else:
		#if is_blocking:
			## Stop blocking (play the reverse block animation or transition to idle)
			#state_machine.travel(reverse_block_animation)  # Or transition to idle
			#is_blocking = false

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
	
func follow_leader(delta):
	if leader_knight:
		# Filter only knights from the parent's children
		var knights = []
		for child in get_parent().get_children():
			if child is Knight:
				knights.append(child)


		# Formation settings
		var knights_per_row = 3  # Number of knights per row
		var row_spacing = 3.0  # Distance between rows
		var column_spacing = 2.5  # Distance between knights in a row

		# Get this knight's position in the formation
		var index = knights.find(self)
		if index == -1:
			return  # Skip if this unit is not a knight

		var row = int(index / knights_per_row)
		var column = index % knights_per_row

		# Get the leader's position and rotation
		var leader_pos = leader_knight.global_transform.origin
		var leader_rotation = leader_knight.model.rotation.y

		# Calculate the formation direction based on the leader's rotation
		var forward = Vector3(sin(leader_rotation), 0, cos(leader_rotation)).normalized()
		var right = Vector3(cos(leader_rotation), 0, -sin(leader_rotation)).normalized()

		# Calculate the target position for the knight in the formation
		var target_position = leader_pos
		target_position -= forward * row * row_spacing  # Move rows back based on leader's forward direction
		target_position += right * (column - ((knights_per_row - 1) / 2.0)) * column_spacing  # Spread columns based on leader's right direction

		# Calculate movement direction
		var move_direction = (target_position - global_transform.origin).normalized()
		var distance_to_target = global_transform.origin.distance_to(target_position)

		# Slow down as the knight approaches the target position
		var slow_factor = clamp(distance_to_target / row_spacing, 0.0, 1.0)
		velocity.x = move_direction.x * speed * slow_factor
		velocity.z = move_direction.z * speed * slow_factor

		# Apply velocity to animation
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)

		# Smooth rotation toward the movement direction
	 
		# Smoothly rotate toward the movement direction
	if velocity.length() > 1.0:
			  # Get the forward direction of the leader's model
			var leader_forward = leader_knight.model.global_transform.basis.z.normalized()

			# Smoothly rotate the follower to align with the leader's forward direction
			var current_forward = model.global_transform.basis.z.normalized()  # Forward vector of the follower model
			var target_rotation_y = atan2(leader_forward.x, leader_forward.z)  # Target rotation based on leader's forward
			var current_rotation_y = atan2(current_forward.x, current_forward.z)  # Current rotation

			model.rotation.y = lerp_angle(current_rotation_y, target_rotation_y, rotation_speed * delta)





func _physics_process(delta):
	velocity.y += -gravity * delta
	
	if  is_leader:
		get_move_input(delta)
		
	else:
		update_target_enemy()

		if target_enemy:
			move_towards_enemy(delta)
		else:
			
			follow_leader(delta)
		


	move_and_slide()
	
	if velocity.length() > 1.0:
		var adjusted_rotation_y = spring_arm.rotation.y + PI
		model.rotation.y = lerp_angle(model.rotation.y, adjusted_rotation_y, rotation_speed * delta)




func _on_changed() -> void:

	is_leader = true
	spring_arm = $SpringArm3D
	$SpringArm3D/Camera3D.make_current()  #


func _on_changed_other() -> void:
	for child in get_parent().get_children():
		if child.is_leader:
			leader_knight = child
			spring_arm = child.get_node("SpringArm3D")
			


signal hurt(int)
var damage_amount = 5


func _on_hurt(damage: int) -> void:
	$Health.take_damage(damage)


	

signal spawn

func spawn_knight():
	if knight_scene:
		print("trying to spawn knight")
		var new_knight = knight_scene.instantiate()
		new_knight.global_transform = Transform3D(global_transform.basis, global_transform.origin + Vector3(2, 0, 2))  # Adjust position
		get_parent().add_child(new_knight)
	else:
		print("Knight scene not assigned!")
		

	player_units = get_parent().get_children()
	print(player_units)




@onready var attack_in_progress = false

func _on_attack_animation_finished() -> void:
		attack_in_progress = false
		
func _on_sword_area_entered(body : Area3D) -> void:
	if attack_in_progress:
		return
	attack_in_progress = true


	if body.is_in_group("hurt_boxes"):
		body.get_parent()._on_hurt(5)
		
var target_enemy = null
@export var detection_range = 5.0
@export var attack_range = 2.0 

func update_target_enemy():
	var enemies = get_parent().get_parent().get_parent().get_node("Enemies").get_children()  # Adjust path to your enemy group
	var closest_distance = detection_range
	target_enemy = null

	for enemy in enemies:
		var distance = global_transform.origin.distance_to(enemy.global_transform.origin)
		if distance < closest_distance:
			closest_distance = distance
			target_enemy = enemy

func move_towards_enemy(delta):
	var enemy_pos = target_enemy.global_transform.origin
	var direction_to_enemy = (enemy_pos - global_transform.origin).normalized()
	var distance_to_enemy = global_transform.origin.distance_to(enemy_pos)

	if distance_to_enemy > attack_range:
		# Move toward the enemy
		velocity.x = direction_to_enemy.x * speed
		velocity.z = direction_to_enemy.z * speed

		# Rotate toward the enemy
		var target_rotation_y = atan2(direction_to_enemy.x, direction_to_enemy.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	else:
		# Stop and attack if within attack range
		velocity.x = 0
		velocity.z = 0
		attack_enemy()

func attack_enemy():


	var random_attack = attacks.pick_random()
	var timer = Timer.new()
	timer.wait_time = get_attack_duration(random_attack)
	timer.one_shot = true
	timer.connect("timeout",_on_attack_animation_finished)
	add_child(timer)
	timer.start()
	state_machine.travel(random_attack)

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
	

	
