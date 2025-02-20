extends CharacterBody3D
class_name Mage

@export var spell_scene : PackedScene  = ResourceLoader.load("res://Scenes/Utils/spell.tscn")
@export var spell_slow : PackedScene  = ResourceLoader.load("res://Scenes/Utils/spell_slow.tscn")
@export var spell_vulnerable : PackedScene  = ResourceLoader.load("res://Scenes/Utils/spell_vulnerable.tscn")
@export var spell_heal : PackedScene  = ResourceLoader.load("res://Scenes/Utils/spell_heal.tscn")
@export var speed = 6.0
@export var acceleration = 4.0
@export var jump_speed = 8.0
@onready var mana_bar = $HUD/ManaBar

var jumping = false

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

var player_units = null
var self_index = self.get_index()

@export var max_mana: int = 100  # The maximum mana the mage can have
var current_mana: int = max_mana  # The current mana the mage has
@export var mana_regeneration_rate: float = 1.0  # Mana regenerated per second

func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		return true  # Mana successfully used
	else:
	
		return false  # Not enough mana

func _on_mana_reward():
	current_mana += 15  # Increase mana (adjust value as needed)

	
var accumulated_mana: float = 0.0  # Tracks fractional mana over time

func _process(delta):
	# Calculate the total mana to regenerate (fractional values included)
	var mana_to_add = mana_regeneration_rate * delta

	# Accumulate fractional mana
	accumulated_mana += mana_to_add

	# Apply only whole-number mana increments
	if accumulated_mana >= 1.0:
		current_mana += int(accumulated_mana)  # Add the whole-number part
		accumulated_mana -= int(accumulated_mana)  # Keep the fractional remainder
		current_mana = min(current_mana, max_mana)  # Clamp to max mana

		# Update mana bar
		mana_bar.value = current_mana
		mana_bar.max_value = max_mana
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
var stationary = false


@onready var camera = $SpringArm3D/Camera3D
@onready var ray_cast = $SpringArm3D/Camera3D/RayCast3D
@export var bullet_speed = 70.0
@export var min_length: float = 2.0  # Minimum zoom distance
@export var max_length: float = 50.0  # Maximum zoom distance
func _unhandled_input(event):
	if is_leader:
		if event is InputEventMouseMotion:
			spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
			spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90.0, 30.0)
			spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
		elif event.is_action_pressed("attack"):
			attack_default()
		elif event.is_action_pressed("spell_slow"):
			attack_slow()
		elif event.is_action_pressed("spell_vulnerable"):
			attack_vulnerable()
		elif event.is_action_pressed("spell_heal"):
			heal()
		elif event.is_action_pressed("zoom_in"):
			spring_arm.spring_length = clamp(spring_arm.spring_length - 1, min_length, max_length)

		elif event.is_action_pressed("zoom_out"):
			spring_arm.spring_length = clamp(spring_arm.spring_length + 1, min_length, max_length)
		elif event.is_action_pressed("charge"):
 # Check if the RayCast3D is colliding
			if ray_cast.is_colliding():
				var collided_object = ray_cast.get_collider()
			
			# Ensure the collider is an enemy mage
				if collided_object and (collided_object.is_in_group("enemy_mages") or collided_object.is_in_group("enemy_knights")):
					var enemy = collided_object
				
				# Find the closest knight
					var closest_knight = find_knight_closest_to(enemy)
				
				# If a knight is found, call its _on_charge method
					if closest_knight:
						closest_knight._on_charge(enemy)
				

		


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
@export var horizontal_offset = 3.0  # Spread between mages
@export var follow_distance = 10.0  # Distance behind the leader

@export var move_speed = 5.0  # Movement speed for the mage



func get_leader_rotation():
	if leader_knight.velocity.length() > 0:
		var direction = leader_knight.velocity.normalized()
		var rotation_y = atan2(direction.x, direction.z)
		return Vector3(0, rad_to_deg(rotation_y), 0)
	return leader_knight.get_rotation_degrees()
	

@export var spell_range: float = 20.0  # Maximum range to detect enemies
@export var spell_cooldown: float = 3.0  # Time between spell casts
var spell_timer: float = 0.0  # Timer to track cooldown
func follow_leader(delta):
	var knights = []
	for child in get_parent().get_children():
		if child is Knight and not child.stationary and not child.charging:
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

			var formation_width = 3  # Number of mages per row

			var index = get_parent().get_children().find(self)
			var row = floor(index / formation_width)
			var column = index % formation_width

			# Calculate the target position behind the group of knights
			var target_position = average_position
			target_position -= average_direction * (row + 1) * row_spacing  # Move rows back
			target_position += Vector3(-average_direction.z, 0, average_direction.x) * (column - (formation_width - 1) / 2.0) * column_spacing  # Spread columns sideways


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
	
	spell_timer -= delta
	if spell_timer <= 0:
		spell_timer = spell_cooldown
		shoot_at_nearest_enemy()

func shoot_at_nearest_enemy():
	var nearest_enemy = null
	var shortest_distance = spell_range

	for enemy in get_parent().get_parent().get_node("Spawners").get_children():
		if enemy is Invading_Knight or enemy is Invading_Mage or enemy is Strong_Invading_Knight: # Replace with your enemy class name
			var distance = global_transform.origin.distance_to(enemy.global_transform.origin)
			if distance < shortest_distance:
				nearest_enemy = enemy
				shortest_distance = distance

	if nearest_enemy:
		var new_spell  = spell_scene.instantiate()
		get_tree().root.add_child(new_spell)
		var tip = get_node("Rig/Skeleton3D/2H_Staff/tip")
		new_spell.global_position = tip.global_position
		var direction = (nearest_enemy.global_position - new_spell.global_position).normalized()
		new_spell.set("direction", direction)  # Pass the direction to the spell

func _physics_process(delta):
	velocity.y += -gravity * delta
	  # Regenerate mana

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
		new_spell.caster = self  # Assign the mage as the caster
	elif spell == spell_heal:
		new_spell = spell_heal.instantiate()
	get_tree().root.add_child(new_spell)
	var tip = get_node("Rig/Skeleton3D/2H_Staff/tip")
	new_spell.global_position = tip.global_position
 
# Get the forward direction of the camera
	ray_cast.target_position = Vector3(0, 0, 100)
	if ray_cast.is_colliding():
# Get the collision point
		var collision_point = ray_cast.get_collision_point()

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


@export var default_spell_mana_cost: int = 5
@export var slow_spell_mana_cost: int = 5
@export var vulnerable_spell_mana_cost: int = 10
@export var heal_spell_mana_cost: int = 10

func attack_default():
	if not is_attacking and use_mana(default_spell_mana_cost):  # Check if there's enough mana
		state_machine.travel("Spellcast_Shoot")
		is_attacking = true
		var attack_timer = Timer.new()
		attack_timer.wait_time = 0.5
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_finished)
		add_child(attack_timer)
		attack_timer.start()
		attack(spell_scene)

func attack_slow():
	if not is_attacking and use_mana(slow_spell_mana_cost):  # Check if there's enough mana
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
	if not is_attacking and use_mana(vulnerable_spell_mana_cost):  # Check if there's enough mana
		state_machine.travel("Spellcast_Shoot")
		is_attacking = true
		var attack_timer = Timer.new()
		attack_timer.wait_time = 1.0
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_finished)
		add_child(attack_timer)
		attack_timer.start()
		attack(spell_vulnerable)

func heal():
	if not is_attacking and use_mana(heal_spell_mana_cost):  # Check if there's enough mana
		state_machine.travel("Spellcast_Shoot")
		is_attacking = true
		var attack_timer = Timer.new()
		attack_timer.wait_time = 1.0
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_finished)
		add_child(attack_timer)
		attack_timer.start()
		attack(spell_heal)

func _on_attack_finished():
	is_attacking = false
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
	

func find_nearest_mage_in_front(max_angle: float = 30.0) -> Node:
	var nearest_mage = null
	var nearest_distance = 20.0
	
	# Convert max_angle to radians for calculations
	var max_angle_rad = deg_to_rad(max_angle)

	# Calculate the player's forward direction using model.rotation
	var forward_direction = Vector3(sin(model.rotation.y), 0, -cos(model.rotation.y)).normalized()

	# Loop through all nodes in the "mages" group
	for mage in get_tree().get_nodes_in_group("enemy_mages"):
		if not Invading_Mage or not is_instance_valid(mage) :
			continue
		
		# Calculate the vector from the player to the mage
		var to_mage = (global_position - mage.global_position).normalized()
		to_mage.y = 0
		# Calculate the angle between the player's forward direction and the direction to the mage
		var angle_to_mage = acos(forward_direction.dot(to_mage))
	
		# Check if the mage is within the specified angle
		if angle_to_mage <= max_angle_rad:
			# Calculate the distance to the mage
			var distance_to_mage = global_transform.origin.distance_to(mage.global_transform.origin)
			
			# Update the nearest mage if this one is closer
			if distance_to_mage < nearest_distance:
				nearest_mage = mage
				nearest_distance = distance_to_mage
	
	return nearest_mage
	

func find_knight_closest_to(enemy_mage: Node) -> Node:
	var closest_knight = null
	var closest_distance = INF
	
	# Loop through all nodes in the "knights" group
	for knight in get_tree().get_nodes_in_group("knights"):
		if not is_instance_valid(knight) or knight.charging:
			continue
		
		# Calculate the distance from the enemy mage to the knight
		var distance = enemy_mage.global_transform.origin.distance_to(knight.global_transform.origin)
		
		# Update the closest knight if this one is closer
		if distance < closest_distance:
			closest_knight = knight
			closest_distance = distance
	
	return closest_knight

	

var targets: Array = []
# When the tracked target dies
func _on_target_died(target: Node) -> void:

	if target in targets:
		return
	targets.append(target)
	_on_mana_reward()  # Notify the mage to grant mana
