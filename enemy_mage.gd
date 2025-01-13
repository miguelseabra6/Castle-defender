extends CharacterBody3D
class_name Enemy_Mage

@export var speed = 7
@export var acceleration = 2.0
@onready var spawn = global_position
@export var spell_scene: PackedScene = ResourceLoader.load("res://Scenes/Utils/enemy_spell.tscn")

@onready var area_min = spawn + Vector3(-5, 0, -5)
@onready var area_max = spawn + Vector3(5, 0, 5)
@export var change_direction_interval = 2.0
@export var idle_chance = 0.3
@export var detection_range = 20.0
@onready var anim_tree = $AnimationTree
@onready var state_machine = $AnimationTree["parameters/playback"]
@onready var model = $Rig
@export var attack_range = 15.0
@export var retreat_distance = 10.0  # Retreat if player is closer than this distance
var is_attacking = false
var target_player = null
var direction = Vector3.ZERO
var time_since_last_change = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var retreat_health_threshold: int = 30
@onready var helmet = get_node("Rig/Skeleton3D/Mage_Hat/Mage_Hat")
@export var rotation_speed = 12.0
var safe_spot: Vector3

signal died(String)

func _ready():
	var char_manager = get_parent().get_parent().get_node("Player Units").get_children()[0]
	died.connect(char_manager._on_enemy_died)
	safe_spot = global_transform.origin
	var material = helmet.get_surface_override_material(0)
	if not material:
		material = StandardMaterial3D.new()
		helmet.set_surface_override_material(0, material)
	material.albedo_color = Color(1, 0, 0)

func _physics_process(delta):
	velocity.y += -gravity * delta

	update_target_player()

	if target_player:
		move_towards_player(delta)
	else:
		idle_wander(delta)

	move_and_slide()

func update_target_player():
	var player_units = get_parent().get_parent().get_node("Player Units").get_children()[0].get_children()
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

	if distance_to_player < retreat_distance:
		# Retreat while attacking if the player is too close
		var retreat_direction = (global_transform.origin - player_pos).normalized()
		velocity.x = retreat_direction.x * speed
		velocity.z = retreat_direction.z * speed

		var target_rotation_y = atan2(-retreat_direction.x, -retreat_direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * rotation_speed)

		if not is_attacking:
			attack()
	elif distance_to_player > attack_range:
		# Approach the player if outside of attack range
		velocity.x = direction_to_player.x * speed
		velocity.z = direction_to_player.z * speed

		var target_rotation_y = atan2(direction_to_player.x, direction_to_player.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation_y, delta * rotation_speed)
	elif distance_to_player <= attack_range and not is_attacking:
		velocity.x = 0
		velocity.z = 0
		attack()
	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(-vl.x, -vl.z) / speed)



func get_random_direction() -> Vector3:
	if randf() < idle_chance:
		return Vector3.ZERO

	var random_x = randf_range(area_min.x, area_max.x)
	var random_z = randf_range(area_min.z, area_max.z)
	var target_position = Vector3(random_x, global_transform.origin.y, random_z)
	return (target_position - global_transform.origin).normalized()

func attack():
	if not is_attacking:
		is_attacking = true
		state_machine.travel("Spellcast_Shoot")

		var spell = spell_scene.instantiate()
		owner.add_child(spell)
		var tip = get_node("Rig/Skeleton3D/2H_Staff/tip")
		spell.global_position = tip.global_position 
		var direction_to_target = ((target_player.global_transform.origin + Vector3(0,1,0))- spell.global_position).normalized()
		spell.set("direction", direction_to_target)

		var attack_timer = Timer.new()
		attack_timer.wait_time = 1.0
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_finished)
		add_child(attack_timer)
		attack_timer.start()

func _on_attack_finished():
	is_attacking = false

func _on_hurt(damage: int):
	$Health.take_damage(damage)
	print("Mage hurt! HP left:", $Health.hp)

func _on_slow():
	speed = 4.5
	var timer = Timer.new()
	timer.wait_time = 10
	timer.one_shot = true
	timer.connect("timeout", _on_slow_timer_finished)
	add_child(timer)
	timer.start()

func _on_slow_timer_finished():
	speed = 7
	
func _on_health_died():
	print("Mage dying...")
	var death_timer = Timer.new()
	death_timer.wait_time = 0.8
	death_timer.one_shot = true
	death_timer.connect("timeout", _on_death_timer_finished)
	add_child(death_timer)
	death_timer.start()
	state_machine.travel("Death_A")

func _on_death_timer_finished():
	queue_free()
	died.emit("Mage")
