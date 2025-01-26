extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_play_button_pressed() -> void:
	SceneHandler.go_to_play()


func _on_quit_pressed() -> void:
	get_tree().quit()
