extends Area3D

@export var speed = 40.0  # Speed of the spell
var direction = Vector3.ZERO  # Movement direction
var caster: Node  # Reference to the mage that cast this spell
var collided = false
func _process(delta):
	if direction != Vector3.ZERO:
		global_position += direction * speed * delta
		
func _on_body_entered(body: Node) -> void:
	if not collided:
		if body.is_in_group("enemy_mages"):
			body._on_hurt(5)
			track_target(body)  # Track this target for the mana reward
			visible = false
			collided = true
		elif body.is_in_group("enemy_knights"):
			body._on_vulnerable()
			track_target(body)  # Track this target for the mana reward
			visible = false
			collided = true
		#if body.is_in_group("knights"):
			#body.enhance()

# Track the target and award mana if it dies within 10 seconds
func track_target(target: Node):
	if not caster:
		return  # If no caster is assigned, skip tracking

	# Listen for the "died" signal from the target
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 10.0
	add_child(timer)
	timer.connect("timeout", self._on_track_timeout.bind(timer,target))  # Timeout if the target doesn't die
	timer.start()
	
	target.died.connect(self._on_target_died.bind(timer,target))  # Reward mana if the target dies


# When the tracked target dies
func _on_target_died(timer: Timer,target: Node) -> void:

	if timer and is_instance_valid(timer):
		timer.queue_free() 
		if caster:
			caster._on_target_died(target)  # Notify the mage to grant mana
			


# Clean up if the target doesn't die within the time limit
func _on_track_timeout(timer: Timer, target: Node):
	timer.queue_free()
