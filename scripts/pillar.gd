extends RigidBody3D

# Buoyancy settings
@export var damping_default_linear: 			float = 0.3
@export var damping_default_angular: 			float = 0.3
@export var damping_water_linear: 				float = 1.6
@export var damping_water_angular: 				float = 0.8
@export var buoyancy_strength: 					float = 20.0
@export var floater_transform:					Array[Vector4] = []						# [pos.x, pos.y, pos.z, size] save size in last value
var floater_volume: 							Array[float] = []						# will be computed at ready
var num_of_floaters: 							int = 0									# Assume floaters are symetrical
@export var mass_center:						= Vector3(0.0, 0.0, 0.0)
@export var mass_multiplier:					float = 35.0
@export var spawn_location:						= Vector2(0.0, 0.0)


func _ready() -> void:
	num_of_floaters = floater_transform.size()
	floater_volume.resize(num_of_floaters)
	for index in num_of_floaters:
		floater_volume[index] = wave_settings.get_sphere_volume(floater_transform[index].w)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var is_submerged: bool = false
	for index in num_of_floaters:
		var position_4d := floater_transform[index]
		var local_pos := Vector3(position_4d.x, position_4d.y, position_4d.z)
		var world_pos := state.transform * local_pos
		var submerged_volume: float = wave_settings.get_submerged_volume_sphere(world_pos, position_4d.w, floater_volume[index])
		var is_in_water: bool = submerged_volume > 0.0
		var force: Vector3
		if is_in_water:
			is_submerged = true
			force = Vector3.UP * buoyancy_strength * submerged_volume * mass
			state.apply_force(force, world_pos - state.transform.origin)
	
	var mass_pos := state.transform * mass_center
	state.apply_force(-Vector3.UP * mass * mass_multiplier, mass_pos - state.transform.origin)
	
	linear_damp = damping_water_linear if is_submerged else damping_default_linear
	angular_damp = damping_water_angular if is_submerged else damping_default_angular
	if spawn_location.length() > 0.01:
		var current_position := Vector2(global_position.x, global_position.z)
		var positional_return_force := (spawn_location - current_position) * 15.0
		apply_central_force(Vector3(positional_return_force.x, 0.0, positional_return_force.y))

func set_spawn_location(pos: Vector3) -> void:
	#position = pos
	position = Vector3(0.0, 10.0, 0.0)
	spawn_location = Vector2(pos.x, pos.z)











































	
