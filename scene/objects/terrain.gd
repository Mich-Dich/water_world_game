@tool
extends MeshInstance3D

@export var foliage_scene: 					PackedScene
var timer: 									Timer


func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(update_position_camera)
	add_child(timer)
	
	var material: Material = get_surface_override_material(0)
	if not material is ShaderMaterial:
		push_warning("Material is not a ShaderMaterial")
		return


func update_position_camera() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return
	var cam_pos: Vector3 = camera.global_position
	var target_position := Vector3(round(cam_pos.x / 4.0) * 4.0, global_position.y, round(cam_pos.z / 4.0) * 4.0)
	if global_position != target_position:
		global_position = target_position
		#TODO: position was updated -> respawn folliage


func spawn_foliage() -> void:
	pass

































	
