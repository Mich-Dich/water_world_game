@tool
extends MeshInstance3D

var material: ShaderMaterial

func _ready() -> void:
	material = get_surface_override_material(0)
	wave_settings.register_material(material)

func _process(delta) -> void:
	# TODO: remove on realease
	if Engine.is_editor_hint():
		var real_time: float = Time.get_ticks_msec() / 1000.0  # seconds since engine start
		if material:
			material.set_shader_parameter("custom_time", real_time)
