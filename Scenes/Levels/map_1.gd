extends Node3D

@onready var pause_menu = $pause_menu
var paused = false

func _ready():
	#pass
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pauseMenu()


func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Engine.time_scale = 0
		pause_menu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused = !paused
