extends Marker3D
class_name Spawner

@export var knight_scene: PackedScene
@export var mage_scene: PackedScene
@export var strong_knight_scene: PackedScene
@export var spawn_time: int  # Time between waves in seconds
@export var spawn_offset: float = 2.0 # Distance between spawned enemies

# Adjusted wave configuration for specific enemy types and counts
var wave_config = [
	{"knights": 0, "mages": 0, "strong_knights": 1},
	{"knights": 3, "mages": 0, "strong_knights": 0},
	{"knights": 3, "mages": 1, "strong_knights": 0},
	{"knights": 3, "mages": 1, "strong_knights": 0},
	{"knights": 4, "mages": 1, "strong_knights": 1}
]

var current_wave: int = 0

func _ready():
	call_deferred("spawn_wave")
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_time
	timer.start()
	timer.timeout.connect(spawn_wave)

func spawn_wave():
	if current_wave < wave_config.size():
		var wave = wave_config[current_wave]
		var spawn_index = 0

		# Spawn knights
		for i in range(wave["knights"]):
			var new_knight = knight_scene.instantiate()
			get_parent().get_parent().add_child(new_knight)
			new_knight.global_position = global_position + Vector3(spawn_index * spawn_offset, 0, 0)
			spawn_index += 1

		# Spawn mages
		for i in range(wave["mages"]):
			var new_mage = mage_scene.instantiate()
			get_parent().get_parent().add_child(new_mage)
			new_mage.global_position = global_position + Vector3(spawn_index * spawn_offset, 0, -spawn_offset)
			spawn_index += 1

		# Spawn strong knights
		for i in range(wave["strong_knights"]):
			var new_strong_knight = strong_knight_scene.instantiate()
			get_parent().get_parent().add_child(new_strong_knight)
			new_strong_knight.global_position = global_position + Vector3(spawn_index * spawn_offset, 0, spawn_offset)
			spawn_index += 1

		current_wave += 1
