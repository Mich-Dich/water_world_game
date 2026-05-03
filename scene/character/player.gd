extends Node

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
@export var previous_camera_type: 		camera_type = camera_type.ORBIT
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
@onready var twist_pivot 				:= $twist_pivot
@onready var pitch_pivot 				:= $twist_pivot/pitch_pivot
@onready var pause_menu					:= $CanvasLayer/pause_menu
@onready var HUD						:= $CanvasLayer/HUD
@export var max_speed:					float = 20.0							# Max speed (units/sec)
var impact_offset: 						Vector3 = Vector3.ZERO
var last_velocity: 						Vector3 = Vector3.ZERO
var current_tilt: 						float = 0.0
var camera:								Camera3D

var move_input_last:					Vector2
@onready var boat: 						RigidBody3D

var drone_ref:							Node3D
var drone_camera_pos:					Node3D
var drone_camera:						Camera3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	wave_settings.register_material($twist_pivot/pitch_pivot/Camera3D/effect.get_surface_override_material(0))
	if current_camera_type == camera_type.ORBIT:
		twist_pivot.top_level = true
	camera = $twist_pivot/pitch_pivot/Camera3D as Camera3D

	# =================== DEV-ONLY ===================
	boat = get_parent()		# TODO: need to change when player is spawned
	# =================== DEV-ONLY ===================

	var drone_scene := load("res://scene/objects/drone.tscn")
	drone_ref = drone_scene.instantiate()
	add_child(drone_ref)
	drone_ref.top_level = true
	drone_ref.global_position = twist_pivot.global_position + (Vector3.UP * 7)
	drone_ref.filming_target = boat
	drone_camera_pos = drone_ref.get_node("camera_pos")
	
	drone_camera = $CanvasLayer/SubViewportContainer/SubViewport/Camera3D
	drone_camera.global_transform = drone_camera_pos.global_transform


func _process(delta: float) -> void:
	# Apply mouse look (rotation only, no movement)
	twist_pivot.global_position = boat.global_position
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, -half_pi, half_pi)
	twist_input = 0.0
	pitch_input = 0.0
	
	drone_camera.global_transform = drone_camera_pos.global_transform
	
	# camera updating
	var target_tilt: float = -move_input_last.x * camera_tilt_strength				# camera tilt
	current_tilt = lerp(current_tilt, target_tilt, delta * camera_tilt_smooth)
	pitch_pivot.rotation.z = current_tilt
	var speed: float = boat.linear_velocity.length()
	var speed_ratio: float = clamp(speed / max_speed, 0.0, 1.0)
	var target_fov: float = lerp(base_fov, max_fov, speed_ratio * fov_speed_factor)
	camera.fov = lerp(camera.fov, target_fov, delta * fov_smooth)
	impact_offset = impact_offset.lerp(Vector3.ZERO, delta * impact_decay)		# impakt shake
	pitch_pivot.position = impact_offset
	if boat:
		HUD.on_speed_changed(Vector2(boat.linear_velocity.x, boat.linear_velocity.z).length())
		HUD.on_rpm_changed(boat.rpm_percentage)
	
	var move_x := Input.get_axis("move_right", "move_left")
	var move_y := Input.get_axis("move_forward", "move_back")
	move_input_last = Vector2(move_x, move_y)
	boat.move_input = move_input_last


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		pause_menu.pause()
	if event.is_action_pressed("toggle_spectator"):
		toggle_spectator()
	if current_camera_type != camera_type.SPECTATOR:							# this input should only be processed when NOT in spectator
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity
		if event.is_action_pressed("reset_player_pos"):
			boat.reset_player(-camera.global_transform.basis.z)


func toggle_spectator() -> void:
	if not spectator_camera:
		return
	if current_camera_type != camera_type.SPECTATOR:
		camera.current = false
		spectator_camera.global_position = camera.global_position
		spectator_camera.current = true
		previous_camera_type = current_camera_type
		current_camera_type = camera_type.SPECTATOR
	else:
		camera.current = true
		spectator_camera.current = false
		current_camera_type = previous_camera_type
		previous_camera_type = camera_type.SPECTATOR










 











	
