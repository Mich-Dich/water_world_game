extends Node

var current_time := 0.0
var water_materials: Array[ShaderMaterial] = []

func _process(delta: float):
	var should_advance = true			# In editor: always animate
	if not Engine.is_editor_hint():
		should_advance = not get_tree().paused
	
	print("Animate: %d", should_advance)
	if should_advance:
		current_time += delta
		for mat in water_materials:		# Update all registered materials at once
			if mat:
				mat.set_shader_parameter("custom_time", current_time)

func register_material(mat: ShaderMaterial):
	if mat not in water_materials:
		water_materials.append(mat)
