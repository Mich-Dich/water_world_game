extends RigidBody3D

# Buoyancy settings
@export var linear_damping_default: float = 0.3     # Drag in air
@export var water_drag: 			float = 1.6
@export var water_angular_drag: 	float = 0.8
@export var buoyancy_strength: 		float = 1060.0
const floater_dist: 				float = 0.8


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# point‑based buoyancy forces
	var is_submersion: bool = false
	var world_point: Vector3 = state.transform.origin - Vector3(0, 0.4, 0)
	var water_height: float = wave_settings.get_wave_height(Vector2(world_point.x, world_point.z))
	var depth: float = water_height - world_point.y   	# positive if submerged
	if depth > 0.0:
		is_submersion = true
		var force := Vector3.UP * buoyancy_strength * depth
		state.apply_central_force(force)
		#DebugDraw3D.draw_arrow(world_point, world_point + Vector3(0, 1.5, 0), Color(0, 1, 0, 1), 0.03, false, 0.001)
	#else:
		#DebugDraw3D.draw_arrow(world_point, world_point + Vector3(0, 1.5, 0), Color(1, 0, 0, 1), 0.03, false, 0.001)

	linear_damp = water_drag if is_submersion else linear_damping_default
	angular_damp = water_angular_drag if is_submersion else 1.0
