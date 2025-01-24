extends Area3D

@export var speed = 40.0  # Speed of the spell
var direction = Vector3.ZERO  # Movement direction

func _process(delta):
	if direction != Vector3.ZERO:
		global_position += direction * speed * delta
		
func _on_body_entered(body: Node) -> void:
	print(body)
	if body.is_in_group("knights"):
		body._on_heal(37.5)
		queue_free()
