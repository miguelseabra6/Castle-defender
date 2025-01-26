extends CharacterBody3D
class_name Knight

@export var speed = 6.0
@export var acceleration = 4.0
@export var jump_speed = 8.0

@export var knight_scene: PackedScene = ResourceLoader.load("res://Scenes/Characters/knight.tscn")

var jumping = false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var model = $Rig
@onready var anim_tree  = $AnimationTree
@onready var spring_arm = null

@onready var helmet = get_node("Rig/Skeleton3D/Knight_Helmet/Knight_Helmet")

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
	
var leader = null
@export var is_leader = false

var is_attacking = false

var player_units = null
var self_index = self.get_index()
var stationary
func _ready():
	var material = helmet.get_surface_override_material(0)
	if not material:
		material = StandardMaterial3D.new()
		helmet.set_surface_override_material(0, material)
	
	material.albedo_color = Color(1, 1, 1)
	$AnimationPlayer.connect("animation_finished", _on_attack_animation_finished)
	died.connect(get_parent()._on_character_died)
	player_units = get_parent().get_children()
	#for child in get_parent().get_parent().get_node("Enemies").get_children():
		#if child.is_in_group("enemies"):
			#hurt.connect(child._on_hurt)
	
		
	
	if not is_leader:
		for child in get_parent().get_children():
			if child.is_leader:
				leader = child
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
		
		#if event.is_action_pressed("attack"):
			#print("attack")
			#attack_enemy()
	#if event.is_action_pressed("block"):
#
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
func _input(_delta):
	if is_leader:
		if Input.is_action_pressed("attack"):

			attack_enemy()
		# Check if the right mouse button (block) is being pressed
		if Input.is_action_pressed("block"):
	
				# Start the block animation once
			state_machine.travel(blocking_animation)
			is_blocking = true

				# Keep playing the blocking animation while the button is held
				#state_machine.travel(blocking_animation)
		elif Input.is_action_just_released("block"):
			if is_blocking:
		# Stop blocking and play reverse block animation or transition to idle
				is_blocking = false
				state_machine.travel(reverse_block_animation)
		if Input.is_action_just_pressed("stationary"):
			stationary = true
			

func get_move_input(delta):
	var vy = velocity.y
	
	var input = Input.get_vector("left", "right","forward","backwards")
	var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	velocity = lerp(velocity, dir * speed, acceleration * delta)
	velocity.y = vy
	velocity = lerp(velocity, dir * speed, acceleration * delta)
	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	#if is_on_floor() and Input.is_action_just_pressed("jump"):
		#velocity.y = jump_speed
		#jumping = true
		#anim_tree.set("parameters/conditions/grounded", false)
		#anim_tree.set("parameters/conditions/jumping", true)
	## We just hit the floor after being in the air
	#if is_on_floor() and not last_floor:
		#jumping = false
		#anim_tree.set("parameters/conditions/jumping", false)
		#anim_tree.set("parameters/conditions/grounded", true)
	#
	#if not is_on_floor() and not jumping:
		#state_machine.travel("Jump_Idle")
		#anim_tree.set("parameters/conditions/grounded", false)
	#last_floor = is_on_floor()
	#
#
#func follow_leader(delta):
	#if leader:
		## Filter only knights from the parent's children
		#var knights = []
		#for child in get_parent().get_children():
			#if child is Knight:
				#knights.append(child)
#
		#var knight_count = knights.size()
#
		## Formation settings
		#var knights_per_row = 4  # Number of knights per row
		#var row_spacing = 3.0  # Distance between rows
		#var column_spacing = 2.5  # Distance between knights in a row
		#if not leader is Knight:
			#row_spacing += 1.0  # Add extra distance in front of the mage
		#
		## Get this knight's position in the formation
		#var index = knights.find(self)
		#if index == -1:
			#return  # Skip if this unit is not a knight
#
		## Get the leader's position and rotation
		#var leader_pos = leader.global_transform.origin
		#var leader_rotation = leader.model.rotation.y
#
		## Calculate the formation direction based on the leader's rotation
		#var forward = Vector3(sin(leader_rotation), 0, cos(leader_rotation)).normalized()
		#var right = Vector3(cos(leader_rotation), 0, sin(leader_rotation)).normalized()
		#var target_position = null
		## Special case for exactly 2 knights
		#if knight_count == 2:
			#if leader is Knight:
				#if index == 0:
					#target_position = leader_pos + right * column_spacing
				#elif index == 1:
					#target_position = leader_pos - right * column_spacing
			#else:
				#if index == 0:
					#target_position = leader_pos + forward * row_spacing + right * column_spacing
				#elif index == 1:
					#target_position = leader_pos + forward * row_spacing - right * column_spacing
		#else:
			## Standard formation logic for more than 2 knights
			#var row = int(index / knights_per_row)
			#var column = index % knights_per_row
#
			#target_position = leader_pos
			#if leader is Knight:
			#
			## Place knights beside the leader in the first row
				#target_position += right * (column - ((knights_per_row - 1) / 2.0)) * column_spacing
				#target_position -= forward * row * row_spacing  # Move rows back based on the leader's forward direction
			#else:
				#target_position += forward * 1.5 * (row + 1) * row_spacing
			#var effective_knights_per_row = min(knights_per_row, knight_count)
			#target_position += right * (column - ((effective_knights_per_row - 1 ) / 2.0)) * column_spacing
#
		## Calculate movement direction
		#var move_direction = (target_position - global_transform.origin).normalized()
		#var distance_to_target = global_transform.origin.distance_to(target_position)
#
		## Slow down as the knight approaches the target position
		#var slow_factor = clamp(distance_to_target / row_spacing, 0.0, 1.0)
		#velocity.x = move_direction.x * speed * slow_factor
		#velocity.z = move_direction.z * speed * slow_factor
#
		## Apply velocity to animation
		#var vl = velocity * model.transform.basis
		#anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
#
		## Smoothly rotate toward the movement direction
		#if velocity.length() > 1.0:
			#var leader_forward = leader.model.global_transform.basis.z.normalized()
			#var current_forward = model.global_transform.basis.z.normalized()
			#var target_rotation_y = atan2(leader_forward.x, leader_forward.z)
			#var current_rotation_y = atan2(current_forward.x, current_forward.z)
			#model.rotation.y = lerp_angle(current_rotation_y, target_rotation_y, rotation_speed * delta)


func follow_leader(delta):
	if leader:
		# Filter only knights from the parent's children
		var knights = []
		for child in get_parent().get_children():
			if child is Knight and not child.stationary and not child.charging:
				knights.append(child)

		var knight_count = knights.size()

		# Formation settings
		var knights_per_row = 4  # Number of knights per row
		var row_spacing = 1.0  # Distance between rows
		var column_spacing = 2.5  # Distance between knights in a row
		if not leader is Knight:
			row_spacing += 1.0  # Add extra distance in front of the mage
		
		# Get this knight's position in the formation
		var index = knights.find(self)
		if index == -1:
			return  # Skip if this unit is not a knight

		# Get the leader's position and rotation
		var leader_pos = leader.global_transform.origin
		var leader_rotation = leader.model.rotation.y

		# Calculate the formation direction based on the leader's rotation
		var forward = Vector3(0,0,1)
		var right = Vector3(-1,0,0)
		var target_position = null
		# Special case for exactly 2 knights
		if knight_count == 2:
			if leader is Knight:
				if index == 0:
					target_position = leader_pos + right * column_spacing
				elif index == 1:
					target_position = leader_pos - right * column_spacing
			else:
				if index == 0:
					target_position = leader_pos + forward * row_spacing + right * column_spacing
				elif index == 1:
					target_position = leader_pos + forward * row_spacing - right * column_spacing
		else:
			# Standard formation logic for more than 2 knights
			var row = int(index / knights_per_row)
			var column = index % knights_per_row

			target_position = leader_pos
			if leader is Knight:
			
			# Place knights beside the leader in the first row
				target_position += right * (column - ((knights_per_row - 1) / 2.0)) * column_spacing
				target_position -= forward * row * row_spacing  # Move rows back based on the leader's forward direction
			else:
				target_position += forward * 1.5 * (row + 1) * row_spacing
			var effective_knights_per_row = min(knights_per_row, knight_count)
			target_position += right * (column - ((effective_knights_per_row - 1 ) / 2.0)) * column_spacing

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

		# Smoothly rotate toward the movement direction
		if velocity.length() > 1.0:
			var leader_forward = leader.model.global_transform.basis.z.normalized()
			var current_forward = model.global_transform.basis.z.normalized()
			var target_rotation_y = atan2(leader_forward.x, leader_forward.z)
			var current_rotation_y = atan2(current_forward.x, current_forward.z)
			model.rotation.y = lerp_angle(current_rotation_y, target_rotation_y, rotation_speed * delta)


func _physics_process(delta):
	velocity.y += -gravity * delta
	
	if stationary:
		update_target_enemy()
		var adjusted_rotation_y = atan2(0,1)
		model.rotation.y = lerp_angle(model.rotation.y, adjusted_rotation_y, rotation_speed * delta)
		velocity.x = 0
		velocity.z = 0
		if target_enemy:
			var enemy_pos = target_enemy.global_transform.origin
			var direction_to_enemy = (enemy_pos - global_transform.origin).normalized()
			var target_rotation_y = atan2(direction_to_enemy.x, direction_to_enemy.z)
			var distance_to_enemy = global_transform.origin.distance_to(enemy_pos)

			if distance_to_enemy < attack_range:
				model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)
				attack_enemy()
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	else:
		if  is_leader:
			get_move_input(delta)
			
		elif not charging:
			update_target_enemy()
			
			if target_enemy:
				move_towards_enemy(delta)
			else:
				
				follow_leader(delta)
		else:
			if not is_instance_valid(target_enemy):
				charging = false
			if target_enemy and is_instance_valid(target_enemy):
				move_towards_enemy(delta)
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
			leader = child
			spring_arm = child.get_node("SpringArm3D")
			



var damage_amount = 5
var i = 0

func _on_hurt(damage: int) -> void:
	$Health.take_damage(damage)


func _on_heal(ammount: int) -> void:
	$Health.heal(ammount)

func _on_low_health():
	if not is_leader and target_enemy:
		var enemy_pos = target_enemy.global_transform.origin
		var direction_away_from_enemy = (global_transform.origin - enemy_pos ).normalized()
	
		
		velocity.x = direction_away_from_enemy.x * (speed + 1)
		velocity.z = direction_away_from_enemy.z * (speed + 1)




@onready var attack_in_progress = false

func _on_attack_animation_finished() -> void:
	attack_in_progress = false
		
func _on_sword_area_entered(body : Area3D) -> void:
	if attack_in_progress:
		return
	attack_in_progress = true
	print(body)
	if body.is_in_group("target_points"):
		print("attacked castle")
	if body.is_in_group("hurt_boxes"):
		print("hurting")
		body.get_parent()._on_hurt(5)
		
var target_enemy = null
@export var detection_range = 4.0
@export var attack_range = 2.0

func update_target_enemy():
	var all_enemies = get_parent().get_parent().get_node("Spawners").get_children()  # Adjust path to your enemy group
	var enemies = []  # Create a new list for filtered enemies

	# Filter the enemies manually
	for enemy in all_enemies:
		if enemy is Invading_Knight or enemy is Invading_Mage or enemy is Strong_Invading_Knight:
			enemies.append(enemy)
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
		var target_rotation_y = atan2(direction_to_enemy.x, direction_to_enemy.z) - 0.1
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
	else:
		# Stop and attack if within attack range
		velocity.x = 0
		velocity.z = 0
		var target_rotation_y = atan2(direction_to_enemy.x, direction_to_enemy.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * 10.0)
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)
		attack_enemy()

func attack_enemy():


	var random_attack = attacks.pick_random()
	var timer = Timer.new()
	timer.wait_time = 1
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

@export var charge_duration_limit = 10.0  # Max duration for charging (in seconds)
var charging = false
var charge_timer: Timer = null

#func _on_charge(enemy_mage: Node) -> void:
	#if charging:
		#print("Already charging!")
		#return
#
	#if not is_instance_valid(enemy_mage):
		#print("Invalid enemy mage passed to _on_charge.")
		#return
#
	#charging = true
	#target_enemy = enemy_mage
#
	#print("Charging at: ", enemy_mage.name)
#
	## Set up the charge duration timer
	#if not charge_timer:
		#charge_timer = Timer.new()
		#charge_timer.one_shot = true
		#charge_timer.connect("timeout", _on_charge_timeout)
		#add_child(charge_timer)
	#charge_timer.wait_time = charge_duration_limit
	#charge_timer.start()
	#print("Charging at:2 ", enemy_mage.name)
	## Charge toward the enemy mage
	#var charge_speed = speed * 2.0  # Adjust the charge multiplier if needed
#
	#while charging:
		## If the enemy mage is no longer valid, stop charging
		#if not is_instance_valid(enemy_mage):
			#print("Enemy mage is no longer valid. Stopping charge.")
			#break
		#print("Charging at:3 ", enemy_mage.name)
		## Calculate the distance to the mage
		#var distance_to_mage = global_transform.origin.distance_to(enemy_mage.global_transform.origin)
#
		## Stop charging if within attack range
		#if distance_to_mage <= attack_range:
			#velocity = Vector3(0, velocity.y, 0)  # Stop horizontal movement
			#attack_enemy()  # Perform the attack
			#break
		#print("Charging at:4 ", enemy_mage.name)
		## Update velocity for charging
		#var direction_to_mage = (enemy_mage.global_transform.origin - global_transform.origin).normalized()
		#velocity.x = direction_to_mage.x * charge_speed
		#velocity.z = direction_to_mage.z * charge_speed
		#print("Charging at:5 ", enemy_mage.name)
		## Smoothly rotate toward the mage during the charge
		#var target_rotation_y = atan2(direction_to_mage.x, direction_to_mage.z)
		#model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, rotation_speed * get_physics_process_delta_time())
#
	   #
#
	## Stop charging
	#_end_charge()

func _on_charge(enemy_mage: Node) -> void:
	target_enemy = enemy_mage
	charging = true
	speed = speed * 1.5
	
	charge_timer = Timer.new()
	charge_timer.one_shot = true
	charge_timer.connect("timeout", _on_charge_timeout)
	add_child(charge_timer)
	charge_timer.wait_time = charge_duration_limit
	charge_timer.start()
	
# Called when the charge duration timer times out
func _on_charge_timeout() -> void:
	print("Charge timed out.")
	charging = false
	speed = speed / 1.5

# Ends the charging state
func _end_charge() -> void:
	charging = false
	velocity = Vector3.ZERO  # Stop all movement
	if charge_timer and charge_timer.is_connected("timeout",_on_charge_timeout):
		charge_timer.stop()
	print("Charge ended.")
