extends Control

func _on_play_button_pressed() -> void:
	SceneHandler.go_to_play()


func _on_exit_pressed() -> void:
	get_tree().quit()
