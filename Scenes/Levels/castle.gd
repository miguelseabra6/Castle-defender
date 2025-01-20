extends Node3D

var markers = {} # Dictionary to store markers and their boolean values

func _ready() -> void:
	var castle = get_children()
	
	for marker in castle:
		if marker is Marker3D:
			markers[marker] = false # Add the marker as a key and set the initial value to false

func occupy(marker):
	markers[marker] = true

func is_occupied(marker):
	return markers[marker]
