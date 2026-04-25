@tool
extends MeshInstance3D

@export var uniform_scalling_range: Vector2 = Vector2(0.25, 0.65)
@export var per_axis_scalling: bool = false
@export var scalling_x_range: Vector2 = Vector2(0.25, 0.5)
@export var scalling_y_range: Vector2 = Vector2(0.25, 0.5)
@export var scalling_z_range: Vector2 = Vector2(0.25, 0.5)
var mesh_0: Mesh = preload("res://assets/mesh/aquatic_water_plant_0.obj")
var mesh_1: Mesh = preload("res://assets/mesh/aquatic_water_plant_1.obj")
var mesh_2: Mesh = preload("res://assets/mesh/aquatic_water_plant_2.obj")
var possible_meshes: Array[Mesh] = [mesh_0, mesh_1, mesh_2]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if possible_meshes.size() > 0:
		mesh = possible_meshes[randi() % possible_meshes.size()]
	else:
		push_warning("No meshes assigned to possible_meshes array")
	if per_axis_scalling:
		scale = Vector3(
			randf_range(scalling_x_range.x, scalling_x_range.y),
			randf_range(scalling_y_range.x, scalling_y_range.y),
			randf_range(scalling_z_range.x, scalling_z_range.y)
		)
	else:
		var uniform_scale: float = randf_range(uniform_scalling_range.x, uniform_scalling_range.y)
		scale = Vector3(uniform_scale, uniform_scale, uniform_scale)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
