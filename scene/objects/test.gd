@tool
extends RigidBody3D

@export var buoyancy_strength: float = 2.0          # Upward force per unit of submersion
@export var water_drag: float = 2.0					# Linear damping when submerged
@export var water_angular_drag: float = 1.0			# Angular damping when submerged
@export var object_height: float = 1.0				# Height of the object (cube size)
@export var float_offset: float = -0.5				# Extra vertical offset (if needed)
var default_linear_damp: float = 0.1
var default_angular_damp: float = 0.01


func _ready():
	pass


func _integrate_forces(state: PhysicsDirectBodyState3D):
	var pos = global_position
	var wave_height = wave_settings.get_wave_height(Vector2(pos.x, pos.z))
	var bottom_y = pos.y - object_height / 2.0
	var water_surface_y = wave_height + float_offset
	var submersion_depth = min(water_surface_y - bottom_y, object_height)	# positive when submerged
	if submersion_depth > 0.0:												# Object is at least partially submerged
		var buoyant_force = Vector3.UP * buoyancy_strength * submersion_depth * mass
		state.apply_central_force(buoyant_force)
		
		linear_damp = water_drag
		angular_damp = water_angular_drag
	else:
		linear_damp = default_linear_damp
		angular_damp = default_angular_damp
