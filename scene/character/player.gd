extends RigidBody3D

# Input
@export var thrust_force:				float = 680000.0						# Force applied along forward axis
@export var turn_torque:				float = 150000.0						# Torque applied for rotation (A/D)
@export var mouse_sensitivity:			float = 0.002
@export var spectator_camera:			Camera3D
var move_input:							Vector2 = Vector2.ZERO
var twist_input:						float = 0.0
var pitch_input:						float = 0.0
const half_pi:							float = (PI/2) - 0.1
enum camera_type {
	ORBIT,
	THIRD_PERSON,
	SPECTATOR
}
@export var current_camera_type: 		camera_type = camera_type.ORBIT
@export var prevoous_camera_type: 		camera_type = camera_type.ORBIT

# Buoyancy settings
@export var buoyancy_strength: 			float = 52000.0
@export var water_damping: 				float = 0.85
@export var water_angular_damping: 		float = 2.6
@export var linear_damping_default: 	float = 0.3								# in air
@export var angular_damping_default: 	float = 0.3								# in air
class floater_data:
	var position: 						Vector3									# all spheres have the same radius for simpler calculation
	var splash_effect: 					Node
	func _init(p_position: Vector3, p_splash_effect: Node) -> void:
		position = p_position
		splash_effect = p_splash_effect
@onready var floaters: 					Array[floater_data] = [
	floater_data.new(Vector3( 0.452, -0.094,  1.890), $water_splash_small_r0),		floater_data.new(Vector3(-0.452, -0.094,  1.890), $water_splash_small_l0),
	floater_data.new(Vector3( 0.478, -0.087,  1.153), $water_splash_small_r1),		floater_data.new(Vector3(-0.478, -0.087,  1.153), $water_splash_small_l1),
	floater_data.new(Vector3( 0.478, -0.102,  0.277), $water_splash_small_r2),		floater_data.new(Vector3(-0.478, -0.102,  0.277), $water_splash_small_l2),
	floater_data.new(Vector3( 0.478, -0.094, -0.912), $water_splash_small_r3),		floater_data.new(Vector3(-0.478, -0.094, -0.912), $water_splash_small_l3),
	floater_data.new(Vector3( 0.46,   0.017, -2.160), $water_splash_small_r4),		floater_data.new(Vector3(-0.46,   0.017, -2.160), $water_splash_small_l4)
]

const floater_radius: 					float = 0.2
var floater_volume:						float = wave_settings.get_sphere_volume(floater_radius)

# Movement
const thrust_pos:						Vector3 = Vector3(0.0, -0.352, 2.373)
@export var thrust_offset: 				Vector3 = Vector3(0, 0.25, 0)
@export var max_speed:					float = 20.0							# Max speed (units/sec)
@export var impact_threshold: 			float = 8.0
@export var impact_strength: 			float = 0.1
@export var impact_decay: 				float = 6.0
@export var camera_tilt_strength: 		float = 0.1
@export var camera_tilt_smooth: 		float = 0.2
@export var base_fov: 					float = 75.0
@export var max_fov: 					float = 95.0
@export var fov_speed_factor: 			float = 0.8
@export var fov_smooth: 				float = 4.0
@export var high_speed_angular_damping: float = 3.0   							# extra angular damping at max speed
@export var downforce_strength: 		float = 1500.0							# downward force per unit of speed
@export var downforce_only_in_water: 	bool = false							# apply downforce only when submerged
var last_velocity: 						Vector3 = Vector3.ZERO
var impact_offset: 						Vector3 = Vector3.ZERO
var current_tilt: 						float = 0.0

# Node referencesw
@onready var motor_wash					:= $motor_wash
@onready var twist_pivot 				:= $twist_pivot
@onready var pitch_pivot 				:= $twist_pivot/pitch_pivot
@onready var pause_menu					:= $pause_menu
@onready var model: 					MeshInstance3D = $MeshInstance3D
var water_splash: 						PackedScene
var timer: 								Timer


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	wave_settings.register_material($twist_pivot/pitch_pivot/Camera3D/effect.get_surface_override_material(0))
	if current_camera_type == camera_type.ORBIT:
		twist_pivot.top_level = true
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.5
	timer.timeout.connect(set_player_position_to_start_of_track)
	timer.autostart = true

	var water_splash_material: Material = load("res://shaders/ppm_water_splash.tres")
	for loc_floaters in floaters:
		var particles := loc_floaters.splash_effect as GPUParticles3D
		if particles:
			particles.process_material = water_splash_material.duplicate(true)


func set_player_position_to_start_of_track() -> void:
	if racetrack.current_track:
		var start_point: Vector2 = racetrack.current_track.control_points[0]		# set start position to start of track
		global_position = Vector3(start_point.x, 0.0, start_point.y)


func _physics_process(delta: float) -> void:
	var thrust_loc := to_global(thrust_pos)
	var prop_depth: float = wave_settings.get_wave_height(Vector2(thrust_loc.x, thrust_loc.z)) - thrust_loc.y
	
	# this input should only be processed when NOT in spectator
	if (prop_depth > 0.0 && prop_depth < 1.5) and current_camera_type != camera_type.SPECTATOR:		# prop submerged but not to deep?
		move_input = Input.get_vector("move_right", "move_left", "move_forward", "move_back")
		var thrust: bool = move_input.y != 0.0
		motor_wash.emitting = thrust
		if thrust:
			var force_dir: Vector3 = global_transform.basis.z * (move_input.y * thrust_force * delta)
			apply_force(force_dir, thrust_loc + thrust_offset - global_position)
		if move_input.x != 0.0:			# turning
			apply_torque(Vector3.UP * move_input.x * turn_torque * delta)
	else:
		motor_wash.emitting = false

	var velocity_change := (linear_velocity - last_velocity).length()
	if velocity_change > impact_threshold:
		print("Registered impace")
		impact_offset += Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * impact_strength
	last_velocity = linear_velocity


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var is_submersion : bool = false											# point‑based buoyancy forces
	for loc_floaters in floaters:
		var world_point: Vector3 = state.transform * loc_floaters.position
		var submerged_volume: float = wave_settings.get_submerged_volume_sphere(world_point, floater_radius, floater_volume)
		var is_in_water: bool = submerged_volume > 0.0
		var force: Vector3
		if is_in_water:
			is_submersion = true
			force = Vector3.UP * buoyancy_strength * submerged_volume
			state.apply_force(force, world_point - state.transform.origin)
		var particles := loc_floaters.splash_effect as GPUParticles3D
		if particles:
			particles.emitting = is_in_water and last_velocity.length() > 1
			var mat := particles.process_material as ParticleProcessMaterial
			if mat:
				var force_multiplier: float = force.length() * 0.0065
				mat.initial_velocity_min = force_multiplier * 0.5
				mat.initial_velocity_max = force_multiplier * 1.1

	linear_damp = water_damping if is_submersion else linear_damping_default	# adjust linear/angular dampening
	angular_damp = water_angular_damping if is_submersion else angular_damping_default

	var speed: float = state.linear_velocity.length()							# stability helper
	var speed_factor: float = clamp(speed / max_speed, 0.0, 1.0)
	angular_damp += high_speed_angular_damping * speed_factor					# Increase rotational inertia at high speed
	if not downforce_only_in_water or is_submersion:							# Downforce – pushes boat downward, scaled by speed
		state.apply_central_force(Vector3.DOWN * downforce_strength * speed_factor)


func _process(delta: float) -> void:
	# Apply mouse look (rotation only, no movement)
	twist_pivot.global_position = global_position
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, -half_pi, half_pi)
	twist_input = 0.0
	pitch_input = 0.0

	# camera updating
	var target_tilt: float = -move_input.x * camera_tilt_strength				# camera tilt
	current_tilt = lerp(current_tilt, target_tilt, delta * camera_tilt_smooth)
	pitch_pivot.rotation.z = current_tilt
	var camera: Camera3D = get_camera()											# speed fov
	var speed: float = linear_velocity.length()
	var speed_ratio: float = clamp(speed / max_speed, 0.0, 1.0)
	var target_fov: float = lerp(base_fov, max_fov, speed_ratio * fov_speed_factor)
	camera.fov = lerp(camera.fov, target_fov, delta * fov_smooth)
	impact_offset = impact_offset.lerp(Vector3.ZERO, delta * impact_decay)		# impakt shake
	pitch_pivot.position = impact_offset


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		pause_menu.pause()
	if event.is_action_pressed("toggle_spectator"):
		toggle_spectator()

	if current_camera_type != camera_type.SPECTATOR:			# this input should only be processed when NOT in spectator
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity
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


func toggle_spectator() -> void:
	if not spectator_camera:
		return
	if current_camera_type != camera_type.SPECTATOR:
		var camera := get_camera()
		camera.current = false
		spectator_camera.global_position = camera.global_position
		spectator_camera.current = true
		prevoous_camera_type = current_camera_type
		current_camera_type = camera_type.SPECTATOR
	else:
		get_camera().current = true
		spectator_camera.current = false
		current_camera_type = prevoous_camera_type
		prevoous_camera_type = camera_type.SPECTATOR


func get_camera() -> Camera3D:
	return pitch_pivot.get_node("Camera3D") as Camera3D
