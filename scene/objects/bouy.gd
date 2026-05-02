extends RigidBody3D

# Buoyancy settings
@export var damping_default_linear: 			float = 0.3
@export var damping_default_angular: 			float = 0.3
@export var damping_water_linear: 				float = 1.6
@export var damping_water_angular: 				float = 0.8
@export var buoyancy_strength: 					float = 5000.0
const floater_radius: 							float = 0.4
var floater_volume:								float = wave_settings.get_sphere_volume(floater_radius)
@export var spawn_location:						= Vector2(0.0, 0.0)



func _ready() -> void:
	pass


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var submerged_volume: float = wave_settings.get_submerged_volume_sphere(state.transform.origin, floater_radius, floater_volume)
	var is_submerged := submerged_volume > 0.0
	if submerged_volume > 0.0:
		var force : Vector3 = Vector3.UP * submerged_volume * buoyancy_strength
		state.apply_central_force(force)
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































	
