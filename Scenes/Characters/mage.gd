extends CharacterBody3D
class_name Mage

@export var spell_scene : PackedScene

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
	player_units = get_parent().get_children()
	
	
	if not is_leader:
		for child in get_parent().get_children():
			if child.is_leader:
				leader_knight = child
				spring_arm = child.get_node("SpringArm3D")
				ray_cast  = child.get_node("SpringArm3D/Camera3D/RayCast3D")
		
	else:
		spring_arm = $SpringArm3D
	anim_tree.set("parameters/Block/playback_speed", -1.0)
	
	var max_index = -1
	
	for child in player_units:
		if child.get_index() > max_index:
			max_index = child.get_index()
	
	if self.get_index() == 0:
		player_units[max_index].changed.connect(_on_changed)
		
	for child in player_units:

		if child != self and child.get_index() == self.get_index() - 1 :
			print(self.get_index())
			child.changed.connect(_on_changed)
		if child != self and child.get_index() != self.get_index() - 1 :
			child.changed_other.connect(_on_changed_other)
		
			
			
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
			print(self.get_signal_connection_list("changed"))
			var new_spell :  = spell_scene.instantiate()
			var particles = GPUParticles3D.new()

		

			# Create and configure the process material
			var particle_material = ParticleProcessMaterial.new()
			particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE  # Set emission shape
			particle_material.emission_sphere_radius = 0.5  # Set sphere radius if needed
			particle_material.color = Color(0, 0.5, 1, 1)  # Set the particle color
			

			# Assign the material to the particles
			particles.process_material = particle_material

			# Add the particles as a child of the spell
			new_spell.add_child(particles)

			# Start emitting



			owner.add_child(new_spell)
			new_spell.global_position = global_position + Vector3(0, 1.5, 1)  # Offset to spawn in front of the camera
		  
		# Get the forward direction of the camera

			ray_cast.target_position = Vector3(0, 0, 100)
			if ray_cast.is_colliding():
		# Get the collision point
				var collision_point = ray_cast.get_collision_point()
				print("Raycast hit at: ", collision_point)

		# Get the object that was hit
				var hit_object = ray_cast.get_collider()
				print("Raycast hit object: ", hit_object)

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

				print("Raycast did not hit anything")
			
			
			
		if event.is_action_pressed("block"):
			print("a")
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
		#var min_distance = 4.0  # Minimum distance to maintain from other followers
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
		#var distance_threshold = 6.5  # Distance to start slowing down
		#var stopping_distance = 6.0   # Distance at which to fully stop
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

@export var horizontal_offset = 3.0  # Spread between mages
@export var follow_distance = 10.0  # Distance behind the leader

@export var move_speed = 4.0  # Movement speed for the mage



#func follow_leader(delta):
	## Get the leader's position and forward direction
	#var leader_position = leader_knight.global_transform.origin
	#var forward_direction = -spring_arm.global_transform.basis.z.normalized()
	#
	## Calculate the target position behind the leader
	#var target_position = leader_position - forward_direction * follow_distance
#
	## Determine left/right offset
	#var offset_direction = -1 if self.get_index() % 2 == 0 else 1
	#target_position += spring_arm.global_transform.basis.x * (horizontal_offset * offset_direction) * (self.get_index() / 2)
	#
	## Smoothly move toward the target position
	#var move_direction = (target_position - global_transform.origin).normalized()
	#velocity.x = move_direction.x * move_speed
	#velocity.z = move_direction.z * move_speed
	#
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
		var knights = []
		var mages = []

		# Separate knights and mages
		for child in get_parent().get_children():
			if child is Knight:
				knights.append(child)
			elif child is Mage:
				mages.append(child)

		# Get the leader's movement direction
		var leader_direction = -leader_knight.velocity.normalized()
		
		# Mage formation settings
		var knights_per_row = 3
		var row_spacing = 3.0
		var column_spacing = 2.0

		# Get this mage's position in the formation
		var index = mages.find(self)
		var row = index / knights_per_row
		var column = index % knights_per_row

		# Calculate the mage's target position behind the knights
		var leader_pos = leader_knight.global_transform.origin
		var target_position = leader_pos
		target_position += leader_direction * (row + knights.size() / knights_per_row + 2) * row_spacing
		target_position += leader_knight.global_transform.basis.x * (column - (knights_per_row / 2.0)) * column_spacing

		# Calculate the movement direction
		var move_direction = (target_position - global_transform.origin).normalized()
		var distance_to_target = global_transform.origin.distance_to(target_position)

		# Slow down as the mage gets closer to its target position
		var slow_factor = clamp(distance_to_target / row_spacing, 0.0, 1.0)
		velocity.x = move_direction.x * speed * slow_factor
		velocity.z = move_direction.z * speed * slow_factor
		if leader_knight.velocity.length() == 0:
			velocity.x = 0
			velocity.z = 0
		# Update animation tree
		var vl = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)

		# Smoothly rotate toward the movement direction
		if velocity.length() > 1.0:
			var target_rotation_y = atan2(move_direction.x, move_direction.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, rotation_speed * delta)

		move_and_slide()




func _physics_process(delta):
	velocity.y += -gravity * delta
	if is_leader:
		# Standard control logic for the leader knight
		
		get_move_input(delta)
		move_and_slide()
		if velocity.length() > 1.0:
			var adjusted_rotation_y = spring_arm.rotation.y + PI
			model.rotation.y = lerp_angle(model.rotation.y, adjusted_rotation_y, rotation_speed * delta)
	else:
		# Follower logic for the knight
		follow_leader(delta)
		move_and_slide()




func _on_changed() -> void:
	if is_leader:
		is_leader = false
		for child in get_parent().get_children():
			if child.is_leader:
				leader_knight = child
				spring_arm = child.get_node("SpringArm3D")
				ray_cast = child.get_node("SpringArm3D/Camera3D/RayCast3D")
				
				# Reparent the camera to the new leader's SpringArm3D
		
	else:
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


signal hurt(int)
var damage_amount = 5
func attack():
	print("attack")
	
func _on_sword_area_entered(body : Area3D) -> void:


	if body.is_in_group("hurt_boxes"):
		hurt.emit(5)
