extends RigidBody3D

# Buoyancy settings
@export var damping_default_linear: 			float = 0.3
@export var damping_default_angular: 			float = 0.3
@export var damping_water_linear: 				float = 1.6
@export var damping_water_angular: 				float = 0.8
@export var buoyancy_strength: 					float = 5000.0
const floater_radius: 							float = 0.4
var floater_volume:								float = wave_settings.get_sphere_volume(floater_radius)
@export var spawn_location:						= Vector2(0.0, 0.0)

@export var player: 							Node3D

var buffered_water_height:						float = 0.0
var frame_counter: 								int = 0
const update_interval:							int = 20


func _ready() -> void:
	frame_counter = randi() % update_interval


func _process(_delta: float) -> void:
	var should_freeze := false

	# Condition 1: close to target position (less than 1 meter)
	var pos_2d := Vector2(global_position.x, global_position.z)
	var distance_to_target := pos_2d.distance_to(spawn_location)
	if distance_to_target < 1.0:
		# Condition 2: ALL players are far (>10m away)
		var all_players_far := true
		if player:
			for p in player:
				if is_instance_valid(p) and global_position.distance_to(p.global_position) <= 10.0:
					all_players_far = false
					break
		
		# Condition 3: NO player's camera can see the object
		var any_camera_looking := false
		if player:
			for p in player:
				if not is_instance_valid(p):
					continue
				# Look for a Camera3D child in the player node
				var cam = p.find_child("Camera3D", true, false) # recursive, not owned
				if cam is Camera3D and cam.is_current() and cam.is_position_in_frustum(global_position):
					any_camera_looking = true
					break
				# Fallback: if no Camera3D child, you might also check for other camera types you use
		else:
			any_camera_looking = true			# FALLBACK
		
		if all_players_far and not any_camera_looking:
			should_freeze = true

	freeze = should_freeze


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Update buffered water height every 10 physics frames
	frame_counter += 1
	if frame_counter >= update_interval:
		var world_pos_2d := Vector2(global_position.x, global_position.z)
		buffered_water_height = wave_settings.get_wave_height(world_pos_2d)
		frame_counter = 0
	
	var submerged_volume: float = wave_settings.get_submerged_volume_sphere_2(state.transform.origin, floater_radius, floater_volume, buffered_water_height)
	var is_submerged := submerged_volume > 0.0
	if submerged_volume > 0.0:
		var force := Vector3.UP * submerged_volume * buoyancy_strength
		state.apply_central_force(force)
	
	linear_damp = damping_water_linear if is_submerged else damping_default_linear
	angular_damp = damping_water_angular if is_submerged else damping_default_angular
	
	if spawn_location.length() > 0.01:
		var current_position := Vector2(global_position.x, global_position.z)
		var positional_return_force := (spawn_location - current_position) * 15.0
		apply_central_force(Vector3(positional_return_force.x, 0.0, positional_return_force.y))


func set_spawn_location(pos: Vector3) -> void:
	#position = pos
	position = Vector3(0.0, 10.0, 0.0)
	spawn_location = Vector2(pos.x, pos.z)



	
