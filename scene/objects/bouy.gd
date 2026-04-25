extends RigidBody3D

# Buoyancy settings
@export var linear_damping_default: 	float = 0.3     # in air
@export var angular_damping_default: 	float = 0.3     # in air

@export var water_damping: 				float = 1.6
@export var water_angular_damping: 		float = 0.8
@export var buoyancy_strength: 			float = 5000.0
const floater_radius: 					float = 0.4
var floater_volume:						float = wave_settings.get_sphere_volume(floater_radius)


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var submerged_volume: float = wave_settings.get_submerged_volume_sphere(state.transform.origin, floater_radius, floater_volume)
	if submerged_volume > 0.0:
		var force : Vector3 = Vector3.UP * submerged_volume * buoyancy_strength
		state.apply_central_force(force)
		linear_damp = water_damping
		angular_damp = water_angular_damping
	else:
		linear_damp = linear_damping_default
		angular_damp = angular_damping_default
