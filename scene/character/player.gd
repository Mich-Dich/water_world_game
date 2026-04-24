extends RigidBody3D

# Input
@export var thrust_force:				float = 680000.0	# Force applied along forward axis
@export var turn_torque:				float = 90000.0		# Torque applied for rotation (A/D)
@export var mouse_sensitivity:			float = 0.002
var move_input:							Vector2 = Vector2.ZERO
var twist_input:						float = 0.0
var pitch_input:						float = 0.0
const half_pi:							float = (PI/2) - 0.1
enum camera_type {
	ORBIT,
	THIRD_PERSON
}
@export var current_camera_type: 		camera_type = camera_type.ORBIT

# Buoyancy settings
@export var buoyancy_strength: 			float = 30000.0
@export var water_damping: 				float = 1.0
@export var water_angular_damping: 		float = 0.8
@export var linear_damping_default: 	float = 0.3     # in air
@export var angular_damping_default: 	float = 0.3     # in air
const floaters: 						Array[Vector3] = [			# all sheres have the same radius for simpler calculation
	Vector3( 0.452, -0.094,  1.89),		Vector3(-0.452, -0.094,  1.89),
	Vector3( 0.478, -0.087,  1.153),	Vector3(-0.478, -0.087,  1.153),
	Vector3( 0.478, -0.102,  0.277),	Vector3(-0.478, -0.102,  0.277),
	Vector3( 0.478, -0.094, -0.63),		Vector3(-0.478, -0.094, -0.63),
	#Vector3( 0.478, -0.065, -1.445),	Vector3(-0.478, -0.065, -1.445),
	Vector3( 0.46,   0.017, -2.16),		Vector3(-0.46,   0.017, -2.16)
]
const floater_radius: 					float = 0.2
var floater_volume:						float = wave_settings.get_shere_volume(floater_radius)

# Movement
const thrust_pos:						Vector3 = Vector3(0.0, -0.352, 2.373)
@export var thrust_offset: 				Vector3 = Vector3(0, 0.25, 0)
@export var max_speed:					float = 20.0		# Max speed (units/sec)

# Node referencesw
@onready var twist_pivot := $twist_pivot
@onready var pitch_pivot := $twist_pivot/pitch_pivot
@onready var model: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	wave_settings.register_material($twist_pivot/pitch_pivot/Camera3D/effect.get_surface_override_material(0))
	if current_camera_type == camera_type.ORBIT:
		twist_pivot.top_level = true


func _physics_process(delta: float) -> void:
	var thrust_loc := to_global(thrust_pos)
	var prop_depth: float = wave_settings.get_wave_height(Vector2(thrust_loc.x, thrust_loc.z)) - thrust_loc.y
	if (prop_depth > 0.0 && prop_depth < 1.5):		# prop submerged but not to deep?
		move_input = Input.get_vector("move_right", "move_left", "move_forward", "move_back")
		if move_input.y != 0.0:			# thrust
			var force_dir: Vector3 = global_transform.basis.z * (move_input.y * thrust_force * delta)
			apply_force(force_dir, thrust_loc + thrust_offset - global_position)
		if move_input.x != 0.0:			# turning
			apply_torque(Vector3.UP * move_input.x * turn_torque * delta)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# point‑based buoyancy forces
	var is_submersion : bool = false
	for floaters_loc_position in floaters:
		var world_point: Vector3 = state.transform * floaters_loc_position
		var submerged_volume: float = wave_settings.get_submerged_volume_sphere(world_point, floater_radius, floater_volume)
		if submerged_volume > 0.0:
			is_submersion = true
			var force := Vector3.UP * buoyancy_strength * submerged_volume
			state.apply_force(force, world_point - state.transform.origin)
			#DebugDraw3D.draw_arrow(world_point, world_point + Vector3(0, 0.5, 0), Color(0, 1, 0, 1), 0.03, false, 0.001)
		#else:
			#DebugDraw3D.draw_arrow(world_point, world_point + Vector3(0, 0.5, 0), Color(1, 0, 0, 1), 0.03, false, 0.001)

	# add movement with body tilt
	# Use [global_rotation] and calculate sloping factor

	# adjust linear/angular dampening
	linear_damp = water_damping if is_submersion else linear_damping_default
	angular_damp = water_angular_damping if is_submersion else angular_damping_default


func _process(delta: float) -> void:
	# Apply mouse look (rotation only, no movement)
	twist_pivot.global_position = global_position
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, -half_pi, half_pi)
	twist_input = 0.0
	pitch_input = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity
	if event.is_action_pressed("escape"):
		$pause_manu.pause()
	if event.is_action_pressed("reset_player_pos"):
		var sea_height : float = wave_settings.get_wave_height(Vector2(global_position.x, global_position.z))
		global_position.y = sea_height + 1
		var camera : Camera3D = get_camera()
		var camera_forward : Vector3 = -camera.global_transform.basis.z
		camera_forward.y = 0.0
		if camera_forward.length_squared() > 0.001:
			camera_forward = -camera_forward.normalized()
			var yaw := atan2(camera_forward.x, camera_forward.z)
			global_rotation = Vector3(0.0, yaw, 0.0)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func get_camera() -> Camera3D:
	return pitch_pivot.get_node("Camera3D") as Camera3D
