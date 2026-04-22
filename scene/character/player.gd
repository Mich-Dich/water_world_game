extends RigidBody3D

# Input
@export var thrust_force := 980000.0						# Force applied along forward axis
@export var turn_torque := 90000.0							# Torque applied for rotation (A/D)
@export var thrust_offset: Vector3 = Vector3(0, 0.24, 0)
@export var max_speed := 20.0								# Max speed (units/sec)
@export var linear_damping_default := 1.0					# Drag in air
@export var mouse_sensitivity := 0.002
var move_input := Vector2.ZERO
var twist_input := 0.0
var pitch_input := 0.0
const half_pi := (PI/2) - 0.1
enum camera_type {
	ORBIT,
	THIRD_PERSON
}
@export var current_camera_type: camera_type = camera_type.ORBIT

# Buoyancy settings
@export var buoyancy_strength: float = 15.0
@export var water_drag: float = 3.0
@export var water_angular_drag: float = 3.0
@export var player_height: float = 2.0        # Approximate height of the capsule/character
@export var float_offset: float = 1.0
const buoyancy_points: Array[Vector3] = [
	Vector3(-0.4, -0.15,  1.6),   # front left (slightly above COM)
	Vector3( 0.4, -0.15,  1.6),   # front right
	Vector3(-0.4, -0.15,  0.9),   # middle left (below COM)
	Vector3( 0.4, -0.15,  0.9),   # middle right
	Vector3(-0.4, -0.15, -0.6),   # middle right
	Vector3( 0.4, -0.15, -0.6),   # middle right
	Vector3(-0.4, -0.1,  -1.7),   # rear left
	Vector3( 0.4, -0.1,  -1.7),   # rear right
]
const thrust_pos:= Vector3(0.0, -0.352, 2.373)

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
	if (wave_settings.get_wave_height(Vector2(thrust_loc.x, thrust_loc.z)) - thrust_loc.y) > 0.0:		# prop submerged?
		move_input = Input.get_vector("move_right", "move_left", "move_forward", "move_back")
		if move_input.y != 0.0:			# thrust
			var force_dir: Vector3 = global_transform.basis.z * (move_input.y * thrust_force * delta)
			apply_force(force_dir, thrust_loc + thrust_offset - global_position)
		if move_input.x != 0.0:			# turning
			apply_torque(Vector3.UP * move_input.x * turn_torque * delta)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# point‑based buoyancy forces
	var is_submersion : bool = false
	for local_point_2d in buoyancy_points:
		var world_point := state.transform * local_point_2d
		var water_height := wave_settings.get_wave_height(Vector2(world_point.x, world_point.z))
		var depth := water_height - world_point.y   	# positive if submerged
		if depth > 0.0:
			is_submersion = true
			#DebugDraw3D.draw_arrow(world_point, world_point + Vector3(0, 0.5, 0), Color(0, 1, 0, 1), 0.03, false, 0.001)
			var force := Vector3.UP * buoyancy_strength * depth * mass
			state.apply_force(force, world_point - state.transform.origin)
		#else:
			#DebugDraw3D.draw_arrow(world_point, world_point + Vector3(0, 0.5, 0), Color(1, 0, 0, 1), 0.03, false, 0.001)

	# add movement with body tilt
	# Use [global_rotation] and calculate sloping factor

	# adjust linear/angular dampening
	linear_damp = water_drag if is_submersion else linear_damping_default
	angular_damp = water_angular_drag if is_submersion else 1.0


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


func get_camera() -> Camera3D:
	return pitch_pivot.get_node("Camera3D") as Camera3D
