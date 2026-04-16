extends RigidBody3D

# Movement settings
@export var walk_speed := 20.0          # Max speed (units/sec)
@export var acceleration_force := 50.0 # How sharply you reach max speed
@export var linear_damping := 6.0      # Drag – higher = quicker stop / lower top speed

# Mouse look
@export var mouse_sensitivity := 0.002

# Node references
@onready var twist_pivot := $twist_pivot
@onready var pitch_pivot := $twist_pivot/pitch_pivot
@onready var model := $MeshInstance3D   # Optional: rotate this to face movement

var move_input := Vector2.ZERO
var twist_input := 0.0
var pitch_input := 0.0

const half_pi := (PI/2) - 0.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	linear_damp = linear_damping


func _physics_process(delta: float) -> void:
	# Get input axes (A/D = left/right, W/S = forward/back)
	move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Calculate desired direction relative to camera (horizontal only)
	var cam := get_camera()
	if cam:
		var forward := cam.global_transform.basis.z
		var right := cam.global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		
		var desired_dir := (forward * move_input.y + right * move_input.x).normalized()
		
		# Apply force in that direction (sharp acceleration)
		apply_central_force(desired_dir * acceleration_force)
		
		# (Optional) rotate model to face movement direction
		if model and move_input.length() > 0.2:
			var target_angle = atan2(desired_dir.x, desired_dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, 10.0 * delta)
	
	# Clamp velocity to max speed (organic, prevents over‑shooting)
	if linear_velocity.length() > walk_speed:
		linear_velocity = linear_velocity.normalized() * walk_speed


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


# Helper to get the camera (avoids errors if camera is removed)
func get_camera() -> Camera3D:
	return pitch_pivot.get_node("Camera3D") as Camera3D
