extends RigidBody3D
class_name Drone

@export var filming_target: 				Node3D

@export var thrust_power 					:= 35.0			# Maximum linear force applied for translation (hover & follow).
@export var linear_damping 					:= 0.9			# Damping factor for linear velocity (higher = more "floaty", lower = more responsive).
@export var angular_damping	 				:= 10.0			# Angular damping factor for smooth rotation.
@export var follow_distance 				:= 12.0			# Distance the drone tries to keep from the target.
@export var follow_height 					:= 6.5			# Height above the target the drone prefers.
@export var yaw_speed 						:= 0.3			# How aggressively the drone yaws to face the target (0.1 - slow, 1.0 - instant).
@export var tilt_sensitivity 				:= 0.05			# How much the drone tilts based on its velocity.
@export var max_tilt_angle_deg 				:= 30.0			# Maximum tilt angle (degrees) in any direction.
@export var max_angular_velocity 			:= 3.0			# Maximum angular velocity (rad/s) to prevent spinning out.
@export var debug_draw 						:= false		# Enable to draw debug lines (requires DebugDraw3D addon).
@onready var camera_pos: 					= $camera_pos

@export var record_fps := 30.0
@export var output_folder := "res://../drone_frames/"

var sub_viewport: SubViewport
var frame_count := 0
var time_accum := 0.0
var recording := false


func _ready() -> void:
	gravity_scale = 0.0
	custom_integrator = true
	sub_viewport = $SubViewport
	recording = true
	DirAccess.make_dir_recursive_absolute(output_folder)						# Create output folder if it doesn't exist


func _process(_delta: float) -> void:
	camera_pos.look_at(filming_target.global_position)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_instance_valid(filming_target):
		return

	var target_flat_forward := -filming_target.global_transform.basis.z
	target_flat_forward.y = 0.0
	target_flat_forward = target_flat_forward.normalized()
	var desired_position := filming_target.global_position
	desired_position += Vector3.UP * follow_height
	desired_position -= target_flat_forward * follow_distance

	var to_target := desired_position - global_position
	var distance := to_target.length()
	var force := to_target.normalized() * thrust_power * distance
	force += Vector3.UP * 9.8 * mass											# exactly counteract gravity

	var target_vel := to_target * 2.0											# simple P controller
	var new_vel := state.linear_velocity.lerp(target_vel, 1.0 - linear_damping)
	state.linear_velocity = new_vel
	var flat_dir := filming_target.global_position - global_position
	flat_dir.y = 0.0
	if flat_dir.length_squared() > 0.001:
		flat_dir = flat_dir.normalized()
		var yaw_basis := Basis.looking_at(flat_dir, Vector3.UP)
		var local_vel := yaw_basis.inverse() * state.linear_velocity
		var max_tilt := deg_to_rad(max_tilt_angle_deg)
		var desired_pitch := clampf(-local_vel.z * tilt_sensitivity, -max_tilt, max_tilt)
		var desired_roll  := clampf(-local_vel.x * tilt_sensitivity, -max_tilt, max_tilt)
		var target_basis := yaw_basis.rotated(yaw_basis.x, -desired_pitch)
		target_basis = target_basis.rotated(target_basis.z, desired_roll)

		# Compute angular velocity needed to smoothly rotate to target_basis
		var q_current := Quaternion(global_transform.basis)
		var q_target := Quaternion(target_basis)
		var delta_q := q_target * q_current.inverse()
		var axis := delta_q.get_axis()
		var angle := delta_q.get_angle()

		if angle > 0.001:
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

































	
