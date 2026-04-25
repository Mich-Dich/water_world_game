extends Camera3D

@export var move_speed: float = 40.0
@export var mouse_sensitivity: float = 0.002

var velocity: Vector3 = Vector3.ZERO
var twist_input: float = 0.0
var pitch_input: float = 0.0

const half_pi: float = (PI/2) - 0.1

func _ready() -> void:
	# Disable this camera until we activate it
	current = false


func _unhandled_input(event: InputEvent) -> void:
	if not current:
		return
	# Mouse look (only when this camera is active and mouse is captured)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity


func _process(delta: float) -> void:
	if not current:
		return
	# Mouse look rotation
	rotate_y(twist_input)
	rotate_object_local(Vector3.RIGHT, pitch_input)
	# Clamp vertical look
	rotation.x = clamp(rotation.x, -half_pi, half_pi)
	twist_input = 0.0
	pitch_input = 0.0

	# WASD movement (world-aligned)
	var input_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += global_transform.basis.x
	if Input.is_key_pressed(KEY_Q):
		input_dir -= Vector3.UP
	if Input.is_key_pressed(KEY_E):
		input_dir += Vector3.UP

	velocity = input_dir.normalized() * move_speed
	global_translate(velocity * delta)
