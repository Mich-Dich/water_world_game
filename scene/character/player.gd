extends Node3D

# Input
@export var thrust_force:					float = 680000.0						# Force applied along forward axis
@export var turn_torque:					float = 150000.0						# Torque applied for rotation (A/D)
@export var mouse_sensitivity:				float = 0.002
@export var follow_camera_smoothness: 		float = 20.0   							# Higher = less lag (try 15–25)
@export var follow_camera_look_speed:	 	float = 15.0     						# Rotation follow speed

var follow_camera_offset:					= Vector3(0, 1.5, 4.0)   				# Closer: up 1.5, back 5.0
var follow_camera_orientation:				float = -1.0
var move_input:								= Vector2.ZERO
var twist_input:							float = 0.0
var pitch_input:							float = 0.0
const half_pi:								float = (PI/2) - 0.1
enum camera_type {
	ORBIT,
	FOLLOW,
	SPECTATOR
}
@export var current_camera_type: 			camera_type = camera_type.ORBIT
@export var previous_camera_type: 			camera_type = camera_type.ORBIT
@export var impact_threshold: 				float = 8.0
@export var impact_strength: 				float = 0.1
@export var impact_decay: 					float = 6.0
@export var camera_tilt_strength: 			float = 0.1
@export var camera_tilt_smooth: 			float = 0.2
@export var base_fov: 						float = 75.0
@export var max_fov: 						float = 95.0
@export var fov_speed_factor: 				float = 0.8
@export var fov_smooth: 					float = 4.0
@export var high_speed_angular_damping: 	float = 3.0   							# extra angular damping at max speed
@onready var twist_pivot 					:= $twist_pivot
@onready var pitch_pivot 					:= $twist_pivot/pitch_pivot
@onready var pause_menu						:= $CanvasLayer/pause_menu
@onready var HUD							:= $CanvasLayer/HUD
@export var max_speed:						float = 20.0							# Max speed (units/sec)
var impact_offset: 							= Vector3.ZERO
var last_velocity: 							= Vector3.ZERO
var current_tilt: 							float = 0.0
var camera:									Camera3D
var move_input_last:						Vector2
@onready var boat_ref: 						RigidBody3D
@onready var drone_feed_display				:= $CanvasLayer/HUD/PanelContainer
var drone_ref:								Node3D
var drone_camera_pos:						Node3D
var drone_camera:							Camera3D


func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	wave_settings.register_material($twist_pivot/pitch_pivot/Camera3D/effect.get_surface_override_material(0))
	if current_camera_type == camera_type.ORBIT:
		twist_pivot.top_level = true
	camera = $twist_pivot/pitch_pivot/Camera3D as Camera3D

	# =================== DEV-ONLY ===================
	boat_ref = get_parent()		# TODO: need to change when player is spawned
	# =================== DEV-ONLY ===================

	var drone_scene := load("res://scene/objects/drone.tscn")
	drone_ref = drone_scene.instantiate()
	add_child(drone_ref)
	drone_ref.top_level = true
	drone_ref.global_position = twist_pivot.global_position + (Vector3.UP * 7)
	drone_ref.filming_target = boat_ref
	drone_camera_pos = drone_ref.get_node("camera_pos")
	drone_camera = $CanvasLayer/HUD/PanelContainer/SubViewportContainer/SubViewport/Camera3D
	drone_camera.global_transform = drone_camera_pos.global_transform

	# Register player in map
	var map_root := get_tree().current_scene
	if map_root.has_method("register_player"):
		map_root.register_player(self)
	else:
		push_error("Map root node does not have 'register_player' method!")
	pause_menu.closing.connect(show_HUD)


func _physics_process(delta: float) -> void:
	# ORBIT mode: update pivots and keep them at boat position
	if current_camera_type == camera_type.ORBIT:
		twist_pivot.global_position = boat_ref.global_position
		twist_pivot.rotate_y(twist_input)
		pitch_pivot.rotate_x(pitch_input)
		pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, -half_pi, half_pi)
		twist_input = 0.0
		pitch_input = 0.0

	elif current_camera_type == camera_type.FOLLOW:								# direct camera control (top_level = true)
		var target_pos := boat_ref.global_position + boat_ref.global_transform.basis * follow_camera_offset
		camera.global_position = camera.global_position.lerp(target_pos, delta * follow_camera_smoothness)
		var target_basis := boat_ref.global_transform.basis
		var flat_forward := follow_camera_orientation * Vector3(target_basis.z.x, 0, target_basis.z.z).normalized()
		var target_rot := Basis().looking_at(flat_forward, Vector3.UP)
		camera.global_transform.basis = camera.global_transform.basis.slerp(target_rot, delta * follow_camera_look_speed)
		camera.global_transform.basis = camera.global_transform.basis.orthonormalized()

	# Update drone camera (used for spectator or pip)
	drone_camera.global_transform = drone_camera_pos.global_transform
	var target_tilt: float = -move_input_last.x * camera_tilt_strength
	current_tilt = lerp(current_tilt, target_tilt, delta * camera_tilt_smooth)
	pitch_pivot.rotation.z = current_tilt
	
	# FOV based on speed
	var speed: float = boat_ref.linear_velocity.length()
	var speed_ratio: float = clamp(speed / max_speed, 0.0, 1.0)
	var target_fov: float = lerp(base_fov, max_fov, speed_ratio * fov_speed_factor)
	camera.fov = lerp(camera.fov, target_fov, delta * fov_smooth)
	
	# Impact shake
	impact_offset = impact_offset.lerp(Vector3.ZERO, delta * impact_decay)
	pitch_pivot.position = impact_offset


func _process(_delta: float) -> void:
	if boat_ref:
		HUD.on_speed_changed(Vector2(boat_ref.linear_velocity.x, boat_ref.linear_velocity.z).length())
		HUD.on_rpm_changed(boat_ref.rpm_percentage)
	
	if current_camera_type != camera_type.SPECTATOR:
		# Store move input for tilt
		var move_x := Input.get_axis("move_right", "move_left")
		var move_y := Input.get_axis("move_forward", "move_back")
		move_input_last = Vector2(move_x, move_y)
		boat_ref.move_input = move_input_last


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		pause_menu.visible = true
		HUD.visible = false
		pause_menu.pause()
	if event.is_action_pressed("toggle_camera_mode"):
		toggle_camera_mode()
	if current_camera_type != camera_type.SPECTATOR:
		if event.is_action_pressed("reset_player_pos"):
			boat_ref.reset_boat(-camera.global_transform.basis.z)
	if current_camera_type == camera_type.ORBIT:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity
	if event.is_action_pressed("show_drone_feed"):
		toggle_drone_feed()


func toggle_drone_feed() -> void:
	drone_feed_display.visible = !drone_feed_display.visible


func toggle_camera_mode() -> void:
	match current_camera_type:
		camera_type.ORBIT:
			current_camera_type = camera_type.FOLLOW
		camera_type.FOLLOW:
			current_camera_type = camera_type.ORBIT
		camera_type.SPECTATOR:
			return  # spectator is toggled separately

	# Apply settings for the new mode
	if current_camera_type == camera_type.ORBIT:
		# Re‑attach camera to pivot system
		camera.top_level = false
		twist_pivot.top_level = true
		# Reset local camera transform (relative to pitch_pivot)
		camera.position = Vector3(0, 0, 4)
		camera.rotation = Vector3.ZERO
		# Reset pivots to avoid jump
		twist_pivot.rotation = Vector3.ZERO
		pitch_pivot.rotation = Vector3.ZERO
	else:
		# Detach camera and set initial follow position
		camera.top_level = true
		twist_pivot.top_level = false
		# Calculate a good starting camera position behind the boat_ref
		var offset := Vector3(0, 2.5, -5.0) if current_camera_type == camera_type.FOLLOW else Vector3(0, 3.0, -4.0)
		camera.global_position = boat_ref.global_position + boat_ref.global_transform.basis * offset
		camera.look_at(boat_ref.global_position + Vector3(0, 1.5, 0), Vector3.UP)


func show_HUD() ->void:
	HUD.visible = true


func control_bloat(boat: RigidBody3D) -> void:
	boat_ref = boat
	follow_camera_offset = boat.follow_camera_offset
	follow_camera_orientation = boat.follow_camera_orientation
	self.reparent(boat_ref)
	position = Vector3(0, 0, 0)
	rotation = Vector3(0, 0, 0)



	
