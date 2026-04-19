@tool
extends Node

# settings for wave calculation
var current_time := 0.0
var sea_height : float = 2
var sea_choppy : float = 3.62
var sea_speed : float = 1.5
var sea_freq : float = 0.032
var water_materials: Array[ShaderMaterial] = []


func _ready():
	for mat in water_materials:
		if mat:
			update_water_params(mat)


func _process(delta: float):
	var should_advance = true
	if not Engine.is_editor_hint():
		should_advance = not get_tree().paused		# pause wave sim if game paused

	if should_advance:
		current_time += delta
		for mat in water_materials:
			if mat:
				mat.set_shader_parameter("custom_time", current_time)


func register_material(mat: ShaderMaterial):
	if mat not in water_materials:
		water_materials.append(mat)


func update_water_params(mat: ShaderMaterial):
	mat.set_shader_parameter("sea_height", sea_height)
	mat.set_shader_parameter("sea_choppy", sea_choppy)
	mat.set_shader_parameter("sea_speed",  sea_speed)
	mat.set_shader_parameter("sea_freq",   sea_freq)


func set_weather_conditions(height: float, rough: float, speed: float, freq: float):
	sea_height = height
	sea_choppy = rough
	sea_speed = speed
	sea_freq = freq
	for mat in water_materials:
		if mat:
			update_water_params(mat)



# ----------------------- Wave height calculation -----------------------
const ITER_GEOMETRY := 3
const OCTAVE_M: Array = [
	[1.6, 1.2],
	[-1.2, 1.6]
]

# 32-bit unsigned hash of a 2D integer grid cell
func hash12(p: Vector2) -> float:
	var qx: int = (int(floor(p.x)) * 1597334677) & 0xFFFFFFFF
	var qy: int = (int(floor(p.y)) * 3812015801) & 0xFFFFFFFF
	var n: int = ((qx ^ qy) * 1597334677) & 0xFFFFFFFF
	return float(n) / 4294967295.0   # 2^32 - 1


# Value noise in range [-1, 1]
func noise(p: Vector2) -> float:
	var i: Vector2 = Vector2(floor(p.x), floor(p.y))
	var f: Vector2 = p - i
	var u: Vector2 = f * f * (Vector2(3, 3) - 2.0 * f)
	var a: float = hash12(i + Vector2(0, 0))
	var b: float = hash12(i + Vector2(1, 0))
	var c: float = hash12(i + Vector2(0, 1))
	var d: float = hash12(i + Vector2(1, 1))
	var low: float = lerp(a, b, u.x)
	var high: float = lerp(c, d, u.x)
	return -1.0 + 2.0 * lerp(low, high, u.y)


# Sea octave function (same as GLSL sea_octave)
func sea_octave(uv: Vector2, choppy: float) -> float:
	var n: float = noise(uv)
	uv += Vector2(n, n)
	var wv: Vector2 = Vector2(1.0, 1.0) - Vector2(abs(sin(uv.x)), abs(sin(uv.y)))
	var swv: Vector2 = Vector2(abs(cos(uv.x)), abs(cos(uv.y)))
	wv.x = lerp(wv.x, swv.x, wv.x)
	wv.y = lerp(wv.y, swv.y, wv.y)
	#wv = wv.lerp(swv, wv)   # mix(wv, swv, wv)
	var prod: float = pow(wv.x * wv.y, 0.65)
	return pow(1.0 - prod, choppy)


# Multiply 2D vector by a 2x2 matrix (stored as array of arrays)
func mat2_mult(m: Array, v: Vector2) -> Vector2:
	return Vector2(
		m[0][0] * v.x + m[0][1] * v.y,
		m[1][0] * v.x + m[1][1] * v.y
	)


# Main height evaluation at world XZ position
func get_wave_height(world_pos: Vector2) -> float:
	var freq: float = sea_freq
	var amp: float = sea_height
	var choppy: float = sea_choppy
	var uv: Vector2 = world_pos
	uv.x *= 0.75
	var h: float = 0.0
	for i in range(ITER_GEOMETRY):
		var d: float = sea_octave((uv + Vector2(current_time * sea_speed, current_time * sea_speed)) * freq, choppy)
		d += sea_octave((uv - Vector2(current_time * sea_speed, current_time * sea_speed)) * freq, choppy)
		h += d * amp
		uv = mat2_mult(OCTAVE_M, uv)
		freq *= 1.9
		amp *= 0.22
		choppy = lerp(choppy, 1.0, 0.2)
	return h
