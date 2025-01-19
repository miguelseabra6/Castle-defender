extends Marker3D
class_name KnightSpawner

@export var enemy_scene : PackedScene
@export var n_spawns : int # How many enemies will the Spawner spawn
@export var spawn_time : int # How much time between spawns

func _ready():
 var timer = Timer.new()
 add_child(timer)
 timer.wait_time = spawn_time
 timer.start()
 timer.timeout.connect(spawn_enemy)



func spawn_enemy():
 var new_enemy = enemy_scene.instantiate()
 get_parent().add_child(new_enemy)
 new_enemy.global_position = global_position
