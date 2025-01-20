extends Node

var menu_scene = "res://scenes/UI/menu.tscn"
var play_scene = "res://Scenes/Levels/map_2.tscn"
func go_to_menu():
 get_tree().change_scene_to_file(menu_scene)
func go_to_play():
 get_tree().change_scene_to_file(play_scene)
