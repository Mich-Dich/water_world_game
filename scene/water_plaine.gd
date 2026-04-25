@tool
extends MeshInstance3D

var material: ShaderMaterial
var timer: Timer


func _ready() -> void:
	material = get_surface_override_material(0)
	wave_settings.register_material(material)
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(update_position_camera)
	add_child(timer)

func _process(delta) -> void:
	# TODO: remove on realease
	if Engine.is_editor_hint():
		var real_time: float = Time.get_ticks_msec() / 1000.0  # seconds since engine start
		if material:
			material.set_shader_parameter("custom_time", real_time)


func update_position_camera() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return			# no active camera
	var camera_position: Vector3 = camera.global_position
	global_position = Vector3(round(camera_position.x), 0.0, round(camera_position.z))
