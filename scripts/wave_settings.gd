@tool
extends Node

@export var sea_height : float = 1.3:
	set(value):
		sea_height = value
		update_water_params()
@export var sea_choppy : float = 4.0:
	set(value):
		sea_choppy = value
		update_water_params()
@export var sea_speed  : float = 1.5:
	set(value):
		sea_speed = value
		update_water_params()
@export var sea_freq   : float = 0.032:
	set(value):
		sea_freq = value
		update_water_params()

var current_time := 0.0
var water_materials: Array[ShaderMaterial] = []


func _ready():
	print("Water Settings: Ready")
	update_water_params()


func _enter_tree():
	if Engine.is_editor_hint():
		# Slight delay ensures ProjectSettings are loaded
		await get_tree().process_frame
		update_water_params()


func _process(delta: float):
	var should_advance = true
	if not Engine.is_editor_hint():
		should_advance = not get_tree().paused		# pause wave sim if pame paused

	if should_advance:
		current_time += delta
		for mat in water_materials:
			if mat:
				mat.set_shader_parameter("custom_time", current_time)


func register_material(mat: ShaderMaterial):
	if mat not in water_materials:
		water_materials.append(mat)


func update_water_params():
	RenderingServer.global_shader_parameter_set("sea_height", sea_height)
	RenderingServer.global_shader_parameter_set("sea_choppy", sea_choppy)
	RenderingServer.global_shader_parameter_set("sea_speed",  sea_speed)
	RenderingServer.global_shader_parameter_set("sea_freq",   sea_freq)


func set_weather_conditions(height: float, rough: float, speed: float, freq: float):
	sea_height = height
	sea_choppy = rough
	sea_speed = speed
	sea_freq = freq
	update_water_params()




func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		print_globals()

func print_globals():
	var h = RenderingServer.global_shader_parameter_get("sea_height")
	var c = RenderingServer.global_shader_parameter_get("sea_choppy")
	var s = RenderingServer.global_shader_parameter_get("sea_speed")
	var f = RenderingServer.global_shader_parameter_get("sea_freq")
	print("Globals: height=", h, " choppy=", c, " speed=", s, " freq=", f)
