#extends Node3D
#
#@export var follow_speed = 8.0  # Smooth following speed
#@export var offset = Vector3(0, 2.0, -5.0)  # Offset relative to the knights (adjust as needed)
#@export var mouse_sensitivity = 0.0015
#@export var rotation_clamp = Vector2(-20.0, 40.0)  # Min and max angles for camera tilt
#
#var targets: Array = []  # Array to hold both knights
#@onready var spring_arm = $SpringArm3D
#
#func _ready():
	## Assume the knights are siblings or in a specific hierarchy
	#targets = get_parent().get_children()  # Get all children, or find specific nodes if needed
#
	#if targets.size() != 2:
		#print("Error: Two knights not found!")
		#return
	#
	#spring_arm.spring_length = 1.5  # Adjust spring arm length (you can change this as needed)
#
#func _process(delta):
	#if targets.size() != 2:
		#return
	#
	## Calculate the midpoint of both knights
	#var knight_pos_1 = targets[0].global_position
	#var knight_pos_2 = targets[1].global_position
	#var midpoint = (knight_pos_1 + knight_pos_2) / 2  # Find the average position between the knights
	#
	## Smoothly move the camera to the midpoint position
	#global_position = global_position.lerp(midpoint + offset, follow_speed * delta)
#
	## Make the camera look at the midpoint (or adjust to look at both knights if needed)
	#look_at(midpoint, Vector3.UP)
#
#func _unhandled_input(event):
	#if event is InputEventMouseMotion:
		## Rotate the spring arm for camera control (if needed)
		#spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		#spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, rotation_clamp.x, rotation_clamp.y)
		#spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
