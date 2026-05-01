extends RigidBody3D

# Input
@export var thrust_force:				float = 2000.0							# Force applied along forward axis
@export var turn_torque:				float = 230.0							# Torque applied for rotation (A/D)
const half_pi:							float = (PI/2) - 0.1
@export var motor_can_add_force:		bool = true
@export var move_input:					= Vector2(0.0, 0.0)
@export var invert_thrust_input:		bool = false
@export var rpm_percentage:				float = 0.0

# RPM simulation curves
@export var rpm_increase_rate_curve:	Curve									# Maps absolute RPM (0-1) to increase rate (rpm/s)
@export var rpm_decrease_rate_curve:	Curve									# Maps absolute RPM (0-1) to decrease rate (rpm/s)
@export var rpm_increase_default_rate:	float = 2.0								# Fallback if no increase curve set
@export var rpm_decrease_default_rate:	float = 4.0								# Fallback if no decrease curve set

# Buoyancy settings
@export var buoyancy_strength: 			float = 90.0
@export var damping_linear_water:		float = 0.85
@export var damping_angular_water: 		float = 2.6
@export var damping_linear_default: 	float = 0.3								# in air
@export var damping_angular_default: 	float = 1.6								# in air

# floaters are sphereical locations used to calculate the water buoyancy effect, they have a splash partical-effect
@export var floater_transform:			Array[Vector4] = []						# [pos.x, pos.y, pos.z, size] save size in last value
@export var splash_effect:				Array[GPUParticles3D] = []
var floater_volume: 					Array[float] = []						# will be computed at ready
var splash_effect_matterial:			Array[ParticleProcessMaterial] = []
var num_of_floaters: 					int = 0									# Assume floaters are symetrical

# pure floaters don't have a splash effect
@export var pure_floater_transform:		Array[Vector4] = []						# [pos.x, pos.y, pos.z, size] save size in last value
var pure_floater_volume: 				Array[float] = []						# will be computed at ready
var num_of_pure_floaters: 				int = 0									# Assume floaters are symetrical

# Movement
@export var thrust_pos:					= Vector3(0.0, -0.352, 2.373)
@export var thrust_offset: 				= Vector3(0, 0.25, 0)
@export var max_speed:					float = 20.0							# Max speed (units/sec)
@export var impact_threshold: 			float = 1.0
@export var impact_strength: 			float = 0.1
@export var impact_decay: 				float = 6.0
@export var high_speed_angular_damping: float = 3.0   							# extra angular damping at max speed
@export var downforce_strength: 		float = 5.0								# downward force per unit of speed
@export var downforce_only_in_water: 	bool = false							# apply downforce only when submerged
var last_velocity: 						= Vector3.ZERO
var impact_offset: 						= Vector3.ZERO
var current_tilt: 						= 0.0

# Node referencesw
@onready var motor_wash:				GPUParticles3D = $motor_wash
var timer: 								Timer


func _ready() -> void:
	# ensure all variables are set
	if not (floater_transform.size() == splash_effect.size()):
		breakpoint

	num_of_floaters = floater_transform.size()
	if invert_thrust_input:
		thrust_force = -thrust_force

	# set some data that can be semi static
	var water_splash_material: Material = load("res://VFX/ppm_water_splash.tres")
	floater_volume.resize(num_of_floaters)
	splash_effect_matterial.resize(num_of_floaters)
	for index in num_of_floaters:
		var effect := splash_effect[index] as GPUParticles3D
		if not effect:
			breakpoint
		effect.process_material = water_splash_material.duplicate(true)
		floater_volume[index] = wave_settings.get_sphere_volume(floater_transform[index].w)
		splash_effect_matterial[index] = effect.process_material
	
	num_of_pure_floaters = pure_floater_transform.size()
	pure_floater_volume.resize(num_of_pure_floaters)
	for index in num_of_pure_floaters:
		pure_floater_volume[index] = wave_settings.get_sphere_volume(pure_floater_transform[index].w)


func _physics_process(delta: float) -> void:
	var thrust_loc := to_global(thrust_pos)
	var prop_depth: float = wave_settings.get_wave_height(Vector2(thrust_loc.x, thrust_loc.z)) - thrust_loc.y

	# calc the RPM percentage
	var target_rpm := move_input.y
	var abs_current: float = abs(rpm_percentage)
	var abs_target: float = abs(target_rpm)
	if abs_target > abs_current:												# accelerating
		var rate: float = sample_rate(rpm_increase_rate_curve, abs_current, rpm_increase_default_rate)
		rpm_percentage = move_toward(rpm_percentage, target_rpm, rate * delta)
	elif abs_target < abs_current:												# decelerating
		var rate: float = sample_rate(rpm_decrease_rate_curve, abs_current, rpm_decrease_default_rate)
		rpm_percentage = move_toward(rpm_percentage, target_rpm, rate * delta)
	rpm_percentage = clamp(rpm_percentage, -1.0, 1.0)

	# add thrust
	if (prop_depth > 0.0 && prop_depth < 1.5) and motor_can_add_force:
		var motor_working: bool = abs(rpm_percentage) > 0.01
		motor_wash.emitting = motor_working
		if motor_working:
			var force_dir: Vector3 = global_transform.basis.z * (rpm_percentage * thrust_force * delta * mass)
			apply_force(force_dir, thrust_loc + thrust_offset - global_position)
		if move_input.x != 0.0:													# turning
			apply_torque(Vector3.UP * move_input.x * turn_torque * mass * delta)
	else:
		motor_wash.emitting = false

	# visual
	var material := motor_wash.process_material
	if material:
		material.initial_velocity_min = rpm_percentage * 4.0
		material.initial_velocity_max = rpm_percentage * 7.0
	var velocity_change := (linear_velocity - last_velocity).length()
	if velocity_change > impact_threshold:
		print("Registered impace")
		impact_offset += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * impact_strength
	last_velocity = linear_velocity


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var floater_submerged: bool = integrate_forces_for_floater(state, floater_transform, floater_volume)
	var pure_floater_submerged: bool = integrate_forces_for_pure_floater(state, pure_floater_transform, pure_floater_volume)
	var is_submerged: bool = floater_submerged and pure_floater_submerged
	if is_submerged:
		linear_damp = damping_linear_water
		angular_damp = damping_angular_water
	else:
		linear_damp = damping_linear_default
		angular_damp = damping_angular_default
	var speed: float = state.linear_velocity.length()							# stability helper
	var speed_factor: float = clamp(speed / max_speed, 0.0, 1.0)
	angular_damp += high_speed_angular_damping * speed_factor					# Increase rotational inertia at high speed
	if not downforce_only_in_water or is_submerged:								# Downforce – pushes boat downward, scaled by speed
		state.apply_central_force(Vector3.DOWN * downforce_strength * mass * speed_factor)


func integrate_forces_for_floater(state: PhysicsDirectBodyState3D, transforms: Array[Vector4], volume: Array[float]) -> bool:
	var is_submerged : bool = false												# point‑based buoyancy forces
	for index in num_of_floaters:
		var position_4d := transforms[index]
		var local_pos := Vector3(position_4d.x, position_4d.y, position_4d.z)
		var world_pos := state.transform * local_pos
		var water_height := wave_settings.get_wave_height(Vector2(world_pos.x, world_pos.z))
		var submerged_volume: float = wave_settings.get_submerged_volume_sphere_2(world_pos, position_4d.w, volume[index], water_height)
		var is_in_water: bool = submerged_volume > 0.0
		var force: Vector3
		if is_in_water:
			is_submerged = true
			force = Vector3.UP * buoyancy_strength * submerged_volume * mass
			state.apply_force(force, world_pos - state.transform.origin)
			#DebugDraw3D.draw_sphere(world_pos, position_4d.w, Color(0, 1, 0, 1), 0.001)
		#else:
			#DebugDraw3D.draw_sphere(world_pos, position_4d.w, Color(1, 0, 0, 1), 0.001)
		splash_effect[index].emitting = is_in_water and last_velocity.length() > 1
		if splash_effect[index].emitting:
			splash_effect[index].global_position.y = water_height + 0.05
		var mat := splash_effect_matterial[index]
		if mat:
			var force_multiplier: float = force.length() * last_velocity.length() * 0.00004
			mat.initial_velocity_min = force_multiplier * 0.7
			mat.initial_velocity_max = force_multiplier * 1.1
	return is_submerged


func integrate_forces_for_pure_floater(state: PhysicsDirectBodyState3D, transforms: Array[Vector4], volume: Array[float]) -> bool:
	var is_submerged : bool = false												# point‑based buoyancy forces
	for index in num_of_pure_floaters:
		var position_4d := transforms[index]
		var local_pos := Vector3(position_4d.x, position_4d.y, position_4d.z)
		var world_pos := state.transform * local_pos
		var water_height := wave_settings.get_wave_height(Vector2(world_pos.x, world_pos.z))
		var submerged_volume: float = wave_settings.get_submerged_volume_sphere_2(world_pos, position_4d.w, volume[index], water_height)
		var is_in_water: bool = submerged_volume > 0.0
		var force: Vector3
		if is_in_water:
			is_submerged = true
			force = Vector3.UP * buoyancy_strength * submerged_volume * mass
			state.apply_force(force, world_pos - state.transform.origin)
			#DebugDraw3D.draw_sphere(world_pos, position_4d.w, Color(0, 1, 0, 1), 0.001)
		#else:
			#DebugDraw3D.draw_sphere(world_pos, position_4d.w, Color(1, 0, 0, 1), 0.001)
	return is_submerged


func reset_player(camera_forward: Vector3) -> void:
	var sea_height : float = wave_settings.get_wave_height(Vector2(global_position.x, global_position.z))
	global_position.y = sea_height + 1
	camera_forward.y = 0.0
	camera_forward = -camera_forward.normalized()
	var yaw := atan2(camera_forward.x, camera_forward.z)
	global_rotation = Vector3(0.0, yaw, 0.0)
	linear_velocity = Vector3(0.0, 0.0, 0.0)
	angular_velocity = Vector3(0.0, 0.0, 0.0)


func sample_rate(curve: Curve, x: float, default_rate: float) -> float:
	if curve and curve.point_count > 0:
		return curve.sample(x)
	return default_rate




































	
