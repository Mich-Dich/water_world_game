@tool
extends MeshInstance3D

@export var float_amplitude: float = 1.0      # if you want to scale height (usually 1.0)
@export var float_offset: float = 0.0         # extra vertical offset

func _process(delta: float) -> void:
	global_position.y = wave_settings.get_wave_height(Vector2(global_position.x, global_position.z))
