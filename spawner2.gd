extends Marker3D
class_name Spawner2

@export var knight_scene: PackedScene
@export var mage_scene: PackedScene
@export var strong_knight_scene: PackedScene
@export var spawn_time: int = 40  # Time between subsequent waves in seconds
@export var first_wave_delay: int = 20  # Delay before the first wave
@export var spawn_offset: float = 2.0  # Distance between spawned enemies
signal wave_cleared(int)


var wave_config = [
	{"knights": 2, "mages": 0, "strong_knights": 0},
	{"knights": 3, "mages": 0, "strong_knights": 0},
	{"knights": 3, "mages": 0, "strong_knights": 0},
	{"knights": 3, "mages": 1, "strong_knights": 0},
	{"knights": 3, "mages": 0, "strong_knights": 1}
]

var current_wave: int = 1
var active_waves: Dictionary = {}  # Tracks enemies for each wave

func _ready():
	var char_manager = get_parent().get_parent().get_parent().get_node("Player Units")
	wave_cleared.connect(char_manager._on_wave_cleared)
	
	# Timer for first wave
	var first_wave_timer = Timer.new()
	add_child(first_wave_timer)
	first_wave_timer.wait_time = first_wave_delay
	first_wave_timer.one_shot = true
	first_wave_timer.connect("timeout", self.spawn_wave)
	first_wave_timer.start()

	# Timer for subsequent waves
	var wave_timer = Timer.new()
	add_child(wave_timer)
	wave_timer.wait_time = spawn_time
	wave_timer.one_shot = false
	wave_timer.connect("timeout", self.spawn_wave)
	wave_timer.start()
	wave_timer.set_paused(true)  # Pause it initially, and start it after the first wave

	# Unpause the wave timer after the first wave spawns
	first_wave_timer.connect("timeout", func() -> void:
		wave_timer.set_paused(false))

func spawn_wave():
	if current_wave <= wave_config.size():
		var wave = wave_config[current_wave - 1]
		var spawn_index = 0
		var enemies_in_wave: Array = []

		# Spawn knights
		for i in range(wave["knights"]):
			var new_knight = knight_scene.instantiate()
			get_parent().get_parent().add_child(new_knight)
			new_knight.global_position = global_position + Vector3(spawn_index * spawn_offset, 0, 0)
			spawn_index += 1
			enemies_in_wave.append("Knight")
			new_knight.died.connect(self._on_enemy_died.bind(current_wave, "Knight"))

		# Spawn mages
		for i in range(wave["mages"]):
			var new_mage = mage_scene.instantiate()
			get_parent().get_parent().add_child(new_mage)
			new_mage.global_position = global_position + Vector3(spawn_index * spawn_offset, 0, -spawn_offset)
			spawn_index += 1
			enemies_in_wave.append("Mage")
			new_mage.died.connect(self._on_enemy_died.bind(current_wave, "Mage"))

		# Spawn strong knights
		for i in range(wave["strong_knights"]):
			var new_strong_knight = strong_knight_scene.instantiate()
			get_parent().get_parent().add_child(new_strong_knight)
			new_strong_knight.global_position = global_position + Vector3(spawn_index * spawn_offset, 0, spawn_offset)
			spawn_index += 1
			enemies_in_wave.append("Strong_knight")
			new_strong_knight.died.connect(self._on_enemy_died.bind(current_wave, "Strong_Knight"))

		# Track enemies for this wave
		active_waves[current_wave] = enemies_in_wave
		current_wave += 1
		print(active_waves)
	else:
		print("No more waves to spawn!")

func _on_enemy_died(wave_id: int, enemy_type: String):
	print("Enemy died: ", enemy_type)
	# Remove the enemy from its wave list
	if wave_id in active_waves and enemy_type in active_waves[wave_id]:
		active_waves[wave_id].erase(enemy_type)

		# Check if the wave is cleared
		if active_waves[wave_id].size() == 0:
			print("Wave %d cleared!" % wave_id)
			active_waves.erase(wave_id)  # Remove cleared wave
			wave_cleared.emit(wave_id)
			
