extends RigidBody3D

# Input
@export var thrust_force:				float = 680000.0						# Force applied along forward axis
@export var turn_torque:				float = 150000.0						# Torque applied for rotation (A/D)
const half_pi:							float = (PI/2) - 0.1
@export var motor_can_add_force:		bool = true
@export var move_input:					= Vector2(0.0, 0.0)

# Buoyancy settings
@export var buoyancy_strength: 			float = 2.0
@export var damping_linear_water:		float = 0.85
@export var damping_angular_water: 		float = 2.6
@export var damping_linear_default: 	float = 0.3								# in air
@export var damping_angular_default: 	float = 0.3								# in air

@export var floater_right_transform:	Array[Vector4] = []
@export var splash_effect_right:		Array[Node] = []
var floater_right_volume: 				Array[float] = []
var splash_effect_matterial_right:		Array[ParticleProcessMaterial] = []

@export var floater_left_transform:		Array[Vector4]
@export var splash_effect_left:			Array[Node] = []
var floater_left_volume: 				Array[float] = []
var splash_effect_matterial_left:		Array[ParticleProcessMaterial] = []
var num_of_floaters: 					int = 0									# Assume floaters are symetrical

# Movement
@export var thrust_pos:					= Vector3(0.0, -0.352, 2.373)
@export var thrust_offset: 				= Vector3(0, 0.25, 0)
@export var max_speed:					float = 20.0							# Max speed (units/sec)
@export var impact_threshold: 			float = 8.0
@export var impact_strength: 			float = 0.1
@export var impact_decay: 				float = 6.0
@export var high_speed_angular_damping: float = 3.0   							# extra angular damping at max speed
@export var downforce_strength: 		float = 1500.0							# downward force per unit of speed
@export var downforce_only_in_water: 	bool = false							# apply downforce only when submerged
var last_velocity: 						= Vector3.ZERO
var impact_offset: 						= Vector3.ZERO
var current_tilt: 						= 0.0

# Node referencesw
@onready var motor_wash					:= $motor_wash
var timer: 								Timer


func _ready() -> void:
	# ensure all variables are set
	if not (floater_right_transform.size() == splash_effect_right.size() and floater_left_transform.size() == splash_effect_left.size()):
		breakpoint
	num_of_floaters = floater_right_transform.size()

	# set some data that can be semi static
	var water_splash_material: Material = load("res://shaders/ppm_water_splash.tres")
	floater_right_volume.resize(num_of_floaters)
	floater_left_volume.resize(num_of_floaters)
	splash_effect_matterial_right.resize(num_of_floaters)
	splash_effect_matterial_left.resize(num_of_floaters)
	for index in num_of_floaters:
		var effect_right := splash_effect_right[index] as GPUParticles3D
		var effect_left := splash_effect_left[index] as GPUParticles3D
		if not effect_right or not effect_left:
			breakpoint
		effect_right.process_material = water_splash_material.duplicate(true)
		effect_left.process_material = water_splash_material.duplicate(true)
		floater_right_volume[index] = wave_settings.get_sphere_volume(floater_right_transform[index].w)
		floater_left_volume[index] = wave_settings.get_sphere_volume(floater_left_transform[index].w)
		splash_effect_matterial_right[index] = effect_right.process_material
		splash_effect_matterial_left[index] = effect_left.process_material


func _physics_process(delta: float) -> void:
	var thrust_loc := to_global(thrust_pos)
	var prop_depth: float = wave_settings.get_wave_height(Vector2(thrust_loc.x, thrust_loc.z)) - thrust_loc.y
	
	# this input should only be processed when NOT in spectator
	if (prop_depth > 0.0 && prop_depth < 1.5) and motor_can_add_force:		# prop submerged but not to deep?
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
		impact_offset += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * impact_strength
	last_velocity = linear_velocity


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var is_submerged_right: bool = integrate_forces_for_floater(floater_right_transform, splash_effect_matterial_right, floater_right_volume, state)
	var is_submerged_left: bool = integrate_forces_for_floater(floater_left_transform, splash_effect_matterial_left, floater_left_volume, state)
	var is_submerged: bool = is_submerged_right or is_submerged_left
	linear_damp = damping_linear_water if is_submerged else damping_linear_default					# adjust linear/angular dampening
	angular_damp = damping_angular_water if is_submerged else damping_angular_default
	var speed: float = state.linear_velocity.length()							# stability helper
	var speed_factor: float = clamp(speed / max_speed, 0.0, 1.0)
	angular_damp += high_speed_angular_damping * speed_factor					# Increase rotational inertia at high speed
	if not downforce_only_in_water or is_submerged:							# Downforce – pushes boat downward, scaled by speed
		state.apply_central_force(Vector3.DOWN * downforce_strength * speed_factor)


func integrate_forces_for_floater(transforms: Array[Vector4], splash_effect_matterial: Array[ParticleProcessMaterial], volume: Array[float], state: PhysicsDirectBodyState3D) -> bool:
	var is_submerged : bool = false											# point‑based buoyancy forces
	for index in num_of_floaters:
		var position_4d := transforms[index]
		var local_pos := Vector3(position_4d.x, position_4d.y, position_4d.z)
		var world_pos := state.transform * local_pos

		var submerged_volume: float = wave_settings.get_submerged_volume_sphere(world_pos, position_4d.w, volume[index])
		var is_in_water: bool = submerged_volume > 0.0
		var force: Vector3
		if is_in_water:
			is_submerged = true
			force = Vector3.UP * buoyancy_strength * submerged_volume
			state.apply_force(force, world_pos - state.transform.origin)
		var mat := splash_effect_matterial[index]
		if mat:
			var force_multiplier: float = force.length() * 0.0065
			mat.initial_velocity_min = force_multiplier * 0.5
			mat.initial_velocity_max = force_multiplier * 1.1
	return is_submerged
