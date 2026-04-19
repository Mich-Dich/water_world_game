extends RigidBody3D

# Input
@export var thrust_force := 80.0              # Force applied along forward axis
@export var turn_torque := 15.0               # Torque applied for rotation (A/D)
@export var max_speed := 20.0                 # Max speed (units/sec)
@export var linear_damping_default := 6.0     # Drag on ground
@export var mouse_sensitivity := 0.002
var move_input := Vector2.ZERO
var twist_input := 0.0
var pitch_input := 0.0

# Buoyancy settings
@export var buoyancy_strength: float = 1.0
@export var water_drag: float = 2.0
@export var water_angular_drag: float = 1.0
@export var player_height: float = 2.0        # Approximate height of the capsule/character
@export var float_offset: float = 1.0
const buoyancy_points: Array[Vector3] = [
	Vector3(-0.4,  0.2,  1.6),   # front left (slightly above COM)
	Vector3( 0.4,  0.2,  1.6),   # front right
	Vector3(-0.4, -0.3,  0.0),   # middle left (below COM)
	Vector3( 0.4, -0.3,  0.0),   # middle right
	Vector3(-0.4,  0.1, -1.7),   # rear left
	Vector3( 0.4,  0.1, -1.7),   # rear right
]

# Node references
@onready var twist_pivot := $twist_pivot
@onready var pitch_pivot := $twist_pivot/pitch_pivot
@onready var model: MeshInstance3D = $MeshInstance3D

const half_pi := (PI/2) - 0.1



func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Get input axes (W/S = forward/back, A/D = left/right)
	move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Apply thrust along the boat's forward direction (global_transform.basis.z)
	var forward_dir := global_transform.basis.z
	if move_input.y != 0.0:
		apply_central_force(forward_dir * move_input.y * thrust_force)

	# Apply turning torque around global Y axis (or body's up)
	if move_input.x != 0.0:
		apply_torque(Vector3.UP * move_input.x * turn_torque * 200000)

	# Clamp velocity to max speed
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	
	#apply_force(Vector3(0.0, 100.0, 0.0), Vector3(-0.1, 0.0, -2))


func _integrate_forces(state: PhysicsDirectBodyState3D):
	# --- Point‑based buoyancy forces ---
	var total_submersion := 0.0
	var weighted_normal := Vector3.ZERO  # For mesh tilt calculation
	
	for local_point_2d in buoyancy_points:
		# Convert Vector2 to local Vector3 (x, 0, y) – assuming X is side‑to‑side, Z is front‑back
		var local_offset := Vector3(local_point_2d.x, 0.0, local_point_2d.y)
		var world_point := state.transform * local_offset
		
		# Get water height at this world XZ
		var water_height := wave_settings.get_wave_height(Vector2(world_point.x, world_point.z))
		var depth := water_height - world_point.y   # positive if submerged
		
		if depth > 0.0:
			total_submersion += depth
			# Apply buoyant force upward at this point
			var force := Vector3.UP * buoyancy_strength * depth * mass
			state.apply_force(force, world_point - state.transform.origin)
			
			# Accumulate for mesh tilt (weighted by depth)
			weighted_normal += Vector3.UP * depth + (world_point - state.transform.origin).normalized() * depth * 0.5
	
	# --- Mesh tilt based on wave surface ---
	if model and total_submersion > 0.0:
		# Compute average tilt direction
		var avg_tilt := weighted_normal.normalized()
		# Create a rotation that aligns the boat's up with the tilted normal
		var target_rotation := Quaternion(Vector3.UP, avg_tilt)
		# Interpolate smoothly (optional)
		model.quaternion = model.quaternion.slerp(target_rotation, 5.0 * state.step)
	
	# --- Drag adjustment (unchanged) ---
	var pos := state.transform.origin
	var wave_height := wave_settings.get_wave_height(Vector2(pos.x, pos.z))
	var bottom_y := pos.y - player_height / 2.0
	var water_surface_y := wave_height + float_offset
	var submersion_depth : float = min(water_surface_y - bottom_y, player_height)
	
	#if submersion_depth > 0.0:
		#linear_damp = water_drag
		#angular_damp = water_angular_drag
	#else:
		#linear_damp = linear_damping_default
		#angular_damp = -1.0


func _process(delta: float) -> void:
	# Apply mouse look (rotation only, no movement)
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
