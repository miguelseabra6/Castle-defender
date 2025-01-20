extends Marker3D
class_name KnightSpawner

@export var enemy_scene: PackedScene
@export var n_spawns: int = 2 # Number of times the spawner can spawn enemies
@export var spawn_time: float  # Time between spawns in seconds

var spawn_count: int = 0 # Tracks how many enemies have been spawned

func _ready():
	call_deferred("spawn_enemy")
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_time
	timer.start()
	timer.timeout.connect(spawn_enemy)

func spawn_enemy():
	if spawn_count < n_spawns:
		var new_enemy = enemy_scene.instantiate()
		get_parent().get_parent().add_child(new_enemy)
		new_enemy.global_position = global_position
		spawn_count += 1
