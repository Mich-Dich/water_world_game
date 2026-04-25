@tool
extends MeshInstance3D

@export var foliage_scene: PackedScene
@export var spawn_size: float = 100.0		# only for now will need to update for movement
@export var step: float = 2.0
@export var grass_threshold: float = 0.5

var timer: Timer

# shader paramerters
var scale_large: float = 0.0
var scale_small: float = 0.0
var amplitude_large: float = 0.0
var amplitude_small: float = 0.0
var color_noise_scale: float = 0.0
var blend_sharpness: float = 0.0

# noise textures
var height_noise_large: Noise
var height_noise_small: Noise
var color_noise: Noise

# fallback to image
var height_image_large: Image
var height_image_small: Image
var color_noise_image: Image
var height_size_large: Vector2i
var height_size_small: Vector2i
var color_noise_size: Vector2i

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(update_position_camera)
	add_child(timer)
	
	var material: Material = get_surface_override_material(0)
	if not material is ShaderMaterial:
		push_warning("Material is not a ShaderMaterial")
		return
	
	var shader_material: ShaderMaterial = material as ShaderMaterial
	var texture_large: Variant = shader_material.get_shader_parameter("heightmap_large")
	var texture_small: Variant = shader_material.get_shader_parameter("heightmap_small")
	var texture_color: Variant = shader_material.get_shader_parameter("color_noise")
	scale_large = shader_material.get_shader_parameter("scale_large")
	scale_small = shader_material.get_shader_parameter("scale_small")
	amplitude_large = shader_material.get_shader_parameter("amplitude_large")
	amplitude_small = shader_material.get_shader_parameter("amplitude_small")
	color_noise_scale = shader_material.get_shader_parameter("color_noise_scale")
	blend_sharpness = shader_material.get_shader_parameter("blend_sharpness")

	if texture_large is NoiseTexture2D:
		height_noise_large = (texture_large as NoiseTexture2D).noise
	else:
		height_image_large = texture_large.get_image()
		if height_image_large:
			height_size_large = height_image_large.get_size()

	if texture_small is NoiseTexture2D:
		height_noise_small = (texture_small as NoiseTexture2D).noise
	else:
		height_image_small = texture_small.get_image()
		if height_image_small:
			height_size_small = height_image_small.get_size()

	if texture_color is NoiseTexture2D:
		color_noise = (texture_color as NoiseTexture2D).noise
	else:
		color_noise_image = texture_color.get_image()
		if color_noise_image:
			color_noise_size = color_noise_image.get_size()
	spawn_foliage()


func update_position_camera() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return
	var cam_pos: Vector3 = camera.global_position
	global_position = Vector3(round(cam_pos.x), global_position.y, round(cam_pos.z))


func _process(delta: float) -> void:
	spawn_foliage()


func sample_noise(noise_object: Noise, world_xz: Vector2, scale: float) -> float:
	return noise_object.get_noise_2d(world_xz.x * scale, world_xz.y * scale)


func is_grass_at(world_xz: Vector2) -> bool:
	var noise_value: float
	if color_noise:
		noise_value = sample_noise(color_noise, world_xz, color_noise_scale)
		#print("noise_value ", noise_value)
	return noise_value > 0.0

func spawn_foliage() -> void:
	if not foliage_scene:
		push_warning("Foliage was not set")
		return
	#for x in range(-spawn_size, spawn_size, step):
		#for z in range(-spawn_size, spawn_size, step):

	var world_position: Vector3 = Vector3(0, 0, -20)
	if is_grass_at(Vector2(world_position.x, world_position.z)):
		DebugDraw3D.draw_line(world_position, world_position + Vector3(0, -40, 0), Color(0.0, 1.0, 0.0, 1.0), 0.001)
	else:
		DebugDraw3D.draw_line(world_position, world_position + Vector3(0, -40, 0), Color(1.0, 0.0, 0.0, 1.0), 0.001)

	world_position = Vector3(0, 0, -10)
	if is_grass_at(Vector2(world_position.x, world_position.z)):
		DebugDraw3D.draw_line(world_position, world_position + Vector3(0, -40, 0), Color(0.0, 1.0, 0.0, 1.0), 0.001)
	else:
		DebugDraw3D.draw_line(world_position, world_position + Vector3(0, -40, 0), Color(1.0, 0.0, 0.0, 1.0), 0.001)
	#print("Spawning Debug")
