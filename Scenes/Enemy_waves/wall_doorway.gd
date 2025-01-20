extends StaticBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_hurt(damage):
	get_parent().get_node("Health").take_damage(damage)
