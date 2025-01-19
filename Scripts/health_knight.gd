extends Node
@export var hp : int
@export var max_hp : int
@export var health_bar : ProgressBar
signal died
@onready var helmet = get_parent().get_node("Rig/Skeleton3D/Knight_Helmet/Knight_Helmet")
signal low_health
func take_damage(damage : int):
	hp = clamp(hp - damage, 0, max_hp)
	update_color_based_on_health()  # Update color based on new health value
	if hp <= 0:
		died.emit()

func update_color_based_on_health():
	if helmet:  # Ensure the helmet reference exists
		var material = helmet.get_surface_override_material(0)
		if not material:
			material = StandardMaterial3D.new()
			helmet.set_surface_override_material(0, material)
		
		# Calculate health ratio (0.0 = no health, 1.0 = full health)
		var health_ratio = float(hp) / float(max_hp)
		
		# Set color based on health ratio
		var red = 1.0  # Red stays at max intensity
		var green = health_ratio  # Green decreases with lower health
		var blue = health_ratio  # Blue decreases with lower health
		
		material.albedo_color = Color(red, green, blue)
