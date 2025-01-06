extends CharacterBody3D
class_name Knight

@export var speed = 5.0
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
signal changed
signal changed_other

var player_units = null
var self_index = self.get_index()

func _ready():
	$AnimationPlayer.connect("animation_finished", _on_attack_animation_finished)
	
	player_units = get_parent().get_children()
	for child in get_parent().get_parent().get_node("Enemies").get_children():
			if child.is_in_group("enemies"):
				hurt.connect(child._on_knight_hurt)
	
		
	
	if not is_leader:
		for child in get_parent().get_children():
			if child.is_leader:
				leader_knight = child
				spring_arm = child.get_node("SpringArm3D")
		
	else:
		spring_arm = $SpringArm3D
		$SpringArm3D/Camera3D.make_current()

	var max_index = -1
	
	for child in player_units:
		if child.get_index() > max_index:
			max_index = child.get_index()
	
	if self.get_index() == 0:
		player_units[max_index].changed.connect(_on_changed)
		
	for child in player_units:

		if child != self and child.get_index() == self.get_index() - 1 :
	
			child.changed.connect(_on_changed)
		if child != self and child.get_index() != self.get_index() - 1 :
			child.changed_other.connect(_on_changed_other)
		

				
			
	
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
	if is_leader:
		if event is InputEventMouseMotion:
			spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
			spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90.0, 30.0)
			spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
		if event.is_action_pressed("change"):
			changed.emit()
			changed_other.emit()
			_on_changed()
	if event.is_action_pressed("attack"):
		attack_enemy()
	if event.is_action_pressed("block"):
	
		$AnimationPlayer.play_backwards(block_animation)
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
	velocity.y = 0
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
	
#func follow_leader(delta):
	#if leader_knight:
		## Calculate the direction to the leader
		#var direction_to_leader = (leader_knight.global_transform.origin - global_transform.origin).normalized()
		#
		## Get the leader's velocity and normalize it to get the direction of its movement
		#var leader_direction = leader_knight.velocity.normalized() if leader_knight.velocity.length() > 0 else Vector3.ZERO
		#
		## Interpolate between the two directions
		#var combined_direction = direction_to_leader.lerp(leader_direction, 0.5).normalized()
		#
		## Separation logic: Adjust direction to avoid nearby followers
		#var separation_force = Vector3.ZERO
		#var min_distance = 3.0  # Minimum distance to maintain from other followers
		#
		#for child in get_parent().get_children():
			#if child != self:
				#var to_other = global_transform.origin - child.global_transform.origin
				#var distance = to_other.length()
				#
				#if distance < min_distance:
					#separation_force += to_other.normalized() * (min_distance - distance)
		#
		## Combine leader-following and separation
		#var final_direction = (combined_direction + separation_force).normalized()
		#
		## Calculate the distance to the leader
		#var distance_to_leader = global_transform.origin.distance_to(leader_knight.global_transform.origin)
		#
		## Update velocity while preserving gravity
	## Update velocity while preserving gravity
		#var distance_threshold = 6  # Distance to start slowing down
		#var stopping_distance = 3.0   # Distance at which to fully stop
		#
		#var closest_knight_distance = INF
		#for child in get_parent().get_children():
			#if child != self and child.global_transform.origin.z < global_transform.origin.z:
				#var distance = global_transform.origin.distance_to(child.global_transform.origin)
				#if distance < closest_knight_distance:
					#closest_knight_distance = distance
#
		## Use the closest distance for the slow factor
#
		#
		## Calculate a smooth factor based on the distance to the leader
		#var slow_factor = clamp((distance_to_leader - stopping_distance) / (distance_threshold - stopping_distance), 0.0, 1.0)
#
		## Apply the smooth factor to the velocity
		#velocity.x = final_direction.x * speed * slow_factor
		#velocity.z = final_direction.z * speed * slow_factor
		#var vl = velocity * model.transform.basis
		#anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	#
		## Smoothly rotate towards the movement direction
		#if velocity.length() > 1.0:
			  ## Get the forward direction of the leader's model
			#var leader_forward = leader_knight.model.global_transform.basis.z.normalized()
#
			## Smoothly rotate the follower to align with the leader's forward direction
			#var current_forward = model.global_transform.basis.z.normalized()  # Forward vector of the follower model
			#var target_rotation_y = atan2(leader_forward.x, leader_forward.z)  # Target rotation based on leader's forward
			#var current_rotation_y = atan2(current_forward.x, current_forward.z)  # Current rotation
#
			#model.rotation.y = lerp_angle(current_rotation_y, target_rotation_y, rotation_speed * delta)

func follow_leader(delta):
	if leader_knight:
		var knights = get_parent().get_children()
		var knight_count = knights.size() -1

		# Formation settings
		var knights_per_row = 3  # Adjust this value to control how many knights per row
		var row_spacing = 4.0  # Spacing between rows
		var column_spacing = 2.5  # Spacing between knights in a row

		# Get this knight's position in the formation
		var index = knights.find(self)
		var row = index / knights_per_row
		var column = index % knights_per_row

		# Calculate the target position in the formation
		var leader_pos = leader_knight.global_transform.origin
		var target_position = leader_pos
		target_position -= leader_knight.global_transform.basis.z * (row + 1) * row_spacing  # Move rows back
		target_position += leader_knight.global_transform.basis.x * (column - (knights_per_row / 2.0)) * column_spacing  # Spread columns

		# Calculate the movement direction
		var move_direction = (target_position - global_transform.origin).normalized()
		var distance_to_target = global_transform.origin.distance_to(target_position)

		# Slow down as the knight gets closer to its target position
		var slow_factor = clamp(distance_to_target / row_spacing, 0.0, 1.0)
		velocity.x = move_direction.x * speed * slow_factor
		velocity.z = move_direction.z * speed * slow_factor
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)


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

	if not is_leader:
		update_target_enemy()

		if target_enemy:
			move_towards_enemy(delta)
		else:
			follow_leader(delta)
	else:
		get_move_input(delta)
		print(get_transform())

	move_and_slide()
	
	if velocity.length() > 1.0:
		var adjusted_rotation_y = spring_arm.rotation.y + PI
		model.rotation.y = lerp_angle(model.rotation.y, adjusted_rotation_y, rotation_speed * delta)




func _on_changed() -> void:
	if is_leader:
		is_leader = false
		for child in get_parent().get_children():
			if child.is_leader:
				leader_knight = child
				spring_arm = child.get_node("SpringArm3D")
				
				# Reparent the camera to the new leader's SpringArm3D
		
	else:
		is_leader = true
		spring_arm = $SpringArm3D
		$SpringArm3D/Camera3D.make_current()  #
		# Reparent the camera back to this knight's SpringArm3D
			


func _on_changed_other() -> void:
	for child in get_parent().get_children():
		if child.is_leader:
			leader_knight = child
			spring_arm = child.get_node("SpringArm3D")
			


signal hurt(int)
var damage_amount = 5
func attack():
	print("attack")


@onready var attack_in_progress = false

func _on_attack_animation_finished() -> void:
		attack_in_progress = false
		
func _on_sword_area_entered(body : Area3D) -> void:
	if attack_in_progress:
		return
	attack_in_progress = true
	print("Is in group? ", body.is_in_group("hurt_boxes"))

	if body.is_in_group("hurt_boxes"):
		body.get_parent()._on_knight_hurt(5)
		
var target_enemy = null
@export var detection_range = 5.0
@export var attack_range = 2.0 

func update_target_enemy():
	var enemies = get_parent().get_parent().get_node("Enemies").get_children()  # Adjust path to your enemy group
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
