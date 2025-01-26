extends Area3D

@export var speed = 40.0  # Speed of the spell
var direction = Vector3.ZERO  # Movement direction

func _process(delta):
	if direction != Vector3.ZERO:
		global_position += direction * speed * delta
		
func _on_body_entered(body: Node) -> void:

	if body.is_in_group("enemy_mages"):
		body._on_slow()
		body._on_hurt(3)
		queue_free()
	if body.is_in_group("enemy_knights"):
		body._on_slow()
		body._on_hurt(5)
		queue_free()
