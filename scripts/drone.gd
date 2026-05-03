extends RigidBody3D
class_name Drone

# ------------------------------------------------------------------ target & physics
@export var filming_target: 				Node3D
@export var thrust_power:					= 25.0			# max linear force (hover & follow)
@export var linear_damping:					= 0.9			# 1.0 = no damping → floaty, 0.0 = instant
@export var angular_damping:				= 10.0			# angular damping for smooth rotation
@export var follow_distance:				= 12.0			# base distance from target
@export var follow_height:					= 6.5			# base height above target
@export var yaw_speed:						= 0.3			# how fast the drone turns (0.1‑1.0)
@export var max_tilt_angle_deg:				= 30.0			# maximum tilt in any direction
@export var max_angular_velocity:			= 3.0			# rad/s cap to avoid spinning out
@export var tilt_accel_sensitivity:			= 0.2			# tilt sensitivity for acceleration
@export var debug_draw:						= false			# enable DebugDraw3D lines
@onready var camera_pos:					= $camera_pos

# ------------------------------------------------------------------ autonomous modes
enum DroneMode { ORBIT, DISTANCE_OSC, STATIC_BEHIND }

@export var mode_min_duration:				= 9.0			# shortest time in one mode (seconds)
@export var mode_max_duration:				= 20.0			# longest time in one mode

# -- orbit mode
@export var orbit_rotation_speed:			= 15.0			# deg/s when in ORBIT mode

# -- fly‑by mode
@export var flyby_width:					= 8.0			# lateral offset from target (right vector)
@export var flyby_length:					= 12.0			# forward/backward extent of the pass
@export var flyby_duration:					= 5.0			# seconds for one full back‑and‑forth

# -- distance oscillating mode (orbits while varying distance & height)
@export var osc_rotation_speed:				= 10.0			# deg/s when in DISTANCE_OSC mode
@export var dist_osc_amp:					= 2.5			# amplitude of distance oscillation
@export var dist_osc_freq:					= 0.1			# frequency (Hz) of distance wave
@export var height_osc_amp:					= 2.5			# amplitude of height oscillation
@export var height_osc_freq:				= 0.03			# frequency of height wave

# ------------------------------------------------------------------ internal state
var current_mode:							DroneMode = DroneMode.DISTANCE_OSC
var mode_timer:								float = 0.0
var _orbit_angle:							float = 0.0
var _flyby_time:							float = 0.0
var _osc_time:								float = 0.0
var desired_position:						Vector3


func _ready() -> void:
	gravity_scale = 0.0
	custom_integrator = true
	_pick_new_mode()


func _process(delta: float) -> void:
	if not is_instance_valid(filming_target):
		return
	camera_pos.look_at(filming_target.global_position)			# update camera rotation (always look at target)

	mode_timer -= delta											# mode timer & random switching
	if mode_timer <= 0.0:
		_pick_new_mode()
		mode_timer = randf_range(mode_min_duration, mode_max_duration)
	_update_movement(delta)										# compute desired position based on current mode


func _pick_new_mode() -> void:
	var modes := DroneMode.values()
	var available: Array[int] = []
	for m in modes:
		if m != current_mode:
			available.append(m)
	if available.is_empty():
		return
	current_mode = DroneMode.DISTANCE_OSC			# available[randi() % available.size()]
	_flyby_time = 0.0
	_osc_time = 0.0


func _update_movement(delta: float) -> void:
	var target_pos := filming_target.global_position
	var target_flat_forward := -filming_target.global_transform.basis.z
	target_flat_forward.y = 0.0
	target_flat_forward = target_flat_forward.normalized()
	var target_right := filming_target.global_transform.basis.x
	target_right.y = 0.0
	target_right = target_right.normalized()

	match current_mode:
		DroneMode.ORBIT:
			_orbit_angle += deg_to_rad(orbit_rotation_speed) * delta
			_orbit_angle = fmod(_orbit_angle, TAU)
			var offset := Vector3(cos(_orbit_angle) * follow_distance, 0.0, 	sin(_orbit_angle) * follow_distance)
			desired_position = target_pos + Vector3.UP * follow_height + offset

		DroneMode.DISTANCE_OSC:
			_orbit_angle += deg_to_rad(osc_rotation_speed) * delta
			_orbit_angle = fmod(_orbit_angle, TAU)
			_osc_time += delta
			var dist := follow_distance + dist_osc_amp * sin(_osc_time * dist_osc_freq * TAU)
			var height := follow_height + height_osc_amp * sin(_osc_time * height_osc_freq * TAU)
			var offset := Vector3(
				cos(_orbit_angle) * dist,
				0.0,
				sin(_orbit_angle) * dist
			)
			desired_position = target_pos + Vector3.UP * height + offset

		DroneMode.STATIC_BEHIND:
			desired_position = target_pos + Vector3.UP * follow_height - target_flat_forward * follow_distance


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_instance_valid(filming_target):
		return
	var to_target := desired_position - global_position
	var distance := to_target.length()
	var force := to_target.normalized() * thrust_power * distance
	force += Vector3.UP * 9.8 * mass
	var prev_vel := state.linear_velocity
	var target_vel := to_target * 2.0
	var new_vel := prev_vel.lerp(target_vel, 1.0 - linear_damping)
	state.linear_velocity = new_vel
	var acceleration := (new_vel - prev_vel) / state.step
	var flat_dir := filming_target.global_position - global_position
	flat_dir.y = 0.0
	if flat_dir.length_squared() > 0.001:
		flat_dir = flat_dir.normalized()
		var yaw_basis := Basis.looking_at(flat_dir, Vector3.UP)
		var local_accel := yaw_basis.inverse() * acceleration
		var max_tilt := deg_to_rad(max_tilt_angle_deg)
		var desired_pitch := clampf(-local_accel.z * tilt_accel_sensitivity, -max_tilt, max_tilt)
		var desired_roll  := clampf(-local_accel.x * tilt_accel_sensitivity, -max_tilt, max_tilt)
		var target_basis := yaw_basis.rotated(yaw_basis.x, -desired_pitch)
		target_basis = target_basis.rotated(target_basis.z, desired_roll)
		var q_current := Quaternion(global_transform.basis)
		var q_target := Quaternion(target_basis)
		var delta_q := q_target * q_current.inverse()
		if delta_q.w < 0.0:
			delta_q = -delta_q
		var angle := delta_q.get_angle()
		if angle > 0.001:
			var axis := delta_q.get_axis().normalized()
			var angular_vel := axis * (angle / state.step) * yaw_speed
			angular_vel = angular_vel.limit_length(max_angular_velocity)
			state.angular_velocity = angular_vel
		else:
			state.angular_velocity = Vector3.ZERO
	else:
		state.angular_velocity = Vector3.ZERO
	state.angular_velocity *= (1.0 - angular_damping * state.step)
	if debug_draw:
		DebugDraw3D.draw_line(global_position, global_position + force.normalized(), Color.GREEN)
		DebugDraw3D.draw_line(global_position, desired_position, Color.YELLOW)
		DebugDraw3D.draw_line(global_position, filming_target.global_position, Color.CYAN)



	
