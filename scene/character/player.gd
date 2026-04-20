extends RigidBody3D

# Input
@export var thrust_force := 50.0              # Force applied along forward axis
@export var turn_torque := 5.0               # Torque applied for rotation (A/D)
@export var max_speed := 20.0                 # Max speed (units/sec)
@export var linear_damping_default := 1.0     # Drag in air
@export var mouse_sensitivity := 0.002
var move_input := Vector2.ZERO
var twist_input := 0.0
var pitch_input := 0.0
var is_submersion : bool = false

# Buoyancy settings
@export var buoyancy_strength: float = 40.0
@export var water_drag: float = 3.0
@export var water_angular_drag: float = 3.0
@export var player_height: float = 2.0        # Approximate height of the capsule/character
@export var float_offset: float = 1.0
const buoyancy_points: Array[Vector3] = [
	Vector3(-0.4,  0.05,  1.6),   # front left (slightly above COM)
	Vector3( 0.4,  0.05,  1.6),   # front right
	Vector3(-0.4, -0.05,  0.9),   # middle left (below COM)
	Vector3( 0.4, -0.05,  0.9),   # middle right
	Vector3(-0.4, -0.05,  -0.6),   # middle right
	Vector3( 0.4, -0.05,  -0.6),   # middle right
	Vector3(-0.4,  0.0, -1.7),   # rear left
	Vector3( 0.4,  0.0, -1.7),   # rear right
]
const thrust_pos:= Vector3(0.0, -0.352, 2.373)

# Node references
@onready var twist_pivot := $twist_pivot
@onready var pitch_pivot := $twist_pivot/pitch_pivot
@onready var model: MeshInstance3D = $MeshInstance3D

const half_pi := (PI/2) - 0.1



func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Get input axes (W/S = forward/back, A/D = left/right)
	move_input = Input.get_vector("move_right", "move_left", "move_forward", "move_back")

	var thrust_loc := to_global(thrust_pos)
	DebugDraw3D.draw_arrow(thrust_loc, thrust_loc + global_transform.basis.z * 2, Color(0, 0, 0, 1), 0.1, false, 0.01)
	if is_submersion:
		if move_input.y != 0.0:			# thrust
			#apply_force(global_transform.basis.z * move_input.y * thrust_force, thrust_loc)
			apply_central_force(global_transform.basis.z * move_input.y * thrust_force)
		if move_input.x != 0.0:			# turning
			apply_torque(Vector3.UP * move_input.x * turn_torque)

	## Clamp velocity to max speed
	#if linear_velocity.length() > max_speed:
		#linear_velocity = linear_velocity.normalized() * max_speed


func _integrate_forces(state: PhysicsDirectBodyState3D):
	## --- Point‑based buoyancy forces ---
	var weighted_normal := Vector3.ZERO  # For mesh tilt calculation
	is_submersion = false
	for local_point_2d in buoyancy_points:
		var world_point := state.transform * local_point_2d
		var water_height := wave_settings.get_wave_height(Vector2(world_point.x, world_point.z))
		var depth := water_height - world_point.y   # positive if submerged
		if depth > 0.0:
			is_submersion = true
			DebugDraw3D.draw_sphere(world_point, 0.25, Color(0, 1, 0, 1), 0.001)
			# Apply buoyant force upward at this point
			var force := Vector3.UP * buoyancy_strength * depth * mass
			state.apply_force(force, world_point - state.transform.origin)
		else:
			DebugDraw3D.draw_sphere(world_point, 0.25, Color(1, 0, 0, 1), 0.001)
			
	## --- Drag adjustment ---
	#var pos := state.transform.origin
	#var wave_height := wave_settings.get_wave_height(Vector2(pos.x, pos.z))
	#var bottom_y := pos.y - player_height / 2.0
	#var water_surface_y := wave_height + float_offset
	#var submersion_depth : float = min(water_surface_y - bottom_y, player_height)
	
	if is_submersion:
		linear_damp = water_drag
		angular_damp = water_angular_drag
	else:
		linear_damp = linear_damping_default
		angular_damp = 1.0


func _process(delta: float) -> void:
	# Apply mouse look (rotation only, no movement)
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, -half_pi, 0)
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
