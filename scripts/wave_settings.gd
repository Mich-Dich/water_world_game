@tool
extends Node

# settings for wave calculation
var current_time := 0.0
var sea_height : float = 0.4
var sea_choppy : float = 4.0
var sea_speed : float = 1.5
var sea_freq : float = 0.08
var water_materials: Array[ShaderMaterial] = []


func _ready() -> void:
	for mat in water_materials:
		if mat:
			update_water_params(mat)


func _process(delta: float) -> void:
	var should_advance: bool = true
	if not Engine.is_editor_hint():
		should_advance = not get_tree().paused		# pause wave sim if game paused

	if should_advance:
		current_time += delta
		for mat in water_materials:
			if mat:
				mat.set_shader_parameter("custom_time", current_time)


func register_material(mat: ShaderMaterial) -> void:
	if mat not in water_materials:
		water_materials.append(mat)
		update_water_params(mat)


func update_water_params(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("sea_height", sea_height)
	mat.set_shader_parameter("sea_choppy", sea_choppy)
	mat.set_shader_parameter("sea_speed",  sea_speed)
	mat.set_shader_parameter("sea_freq",   sea_freq)


func set_weather_conditions(height: float, rough: float, speed: float, freq: float) -> void:
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
const VEC2_ZERO := Vector2(0, 0)
const VEC2_RIGHT := Vector2(1, 0)
const VEC2_UP := Vector2(0, 1)
const VEC2_ONE := Vector2(1, 1)
const VEC2_SMOOTH := Vector2(3, 3)

# 32-bit unsigned hash – now takes two ints directly to skip Vector2 creation
func hash12(x: int, y: int) -> float:
	var qx: int = (x * 1597334677) & 0xFFFFFFFF
	var qy: int = (y * 3812015801) & 0xFFFFFFFF
	var n: int = ((qx ^ qy) * 1597334677) & 0xFFFFFFFF
	return float(n) / 4294967295.0   # 2^32 - 1


# Value noise [-1, 1] – uses floori for an integer result directly
func noise(p: Vector2) -> float:
	var ix: int = floori(p.x)
	var iy: int = floori(p.y)
	var fx: float = p.x - ix
	var fy: float = p.y - iy
	var ux: float = fx * fx * (3.0 - 2.0 * fx)
	var uy: float = fy * fy * (3.0 - 2.0 * fy)
	# 4 corners – no more Vector2 addition; coordinates are simple ints
	var a: float = hash12(ix,     iy)
	var b: float = hash12(ix + 1, iy)
	var c: float = hash12(ix,     iy + 1)
	var d: float = hash12(ix + 1, iy + 1)
	var low: float = lerp(a, b, ux)
	var high: float = lerp(c, d, ux)
	return -1.0 + 2.0 * lerp(low, high, uy)


# Sea octave – avoids unnecessary Vector2 allocations
func sea_octave(uv: Vector2, choppy: float) -> float:
	var n: float = noise(uv)
	uv.x += n
	uv.y += n
	# 1 - |sin| and |cos|
	var wx: float = 1.0 - abs(sin(uv.x))
	var wy: float = 1.0 - abs(sin(uv.y))
	var swx: float = abs(cos(uv.x))
	var swy: float = abs(cos(uv.y))
	# blend using wx/wy as weights
	wx = lerp(wx, swx, wx)
	wy = lerp(wy, swy, wy)
	var prod: float = pow(wx * wy, 0.65)
	return pow(1.0 - prod, choppy)


# Multiply 2D vector by a 2x2 matrix (stored as array of arrays)
func mat2_mult(m: Array, v: Vector2) -> Vector2:
	return Vector2(
		m[0][0] * v.x + m[0][1] * v.y,
		m[1][0] * v.x + m[1][1] * v.y
	)


# Main height evaluation – inlined matrix multiplication and time offset
func get_wave_height(world_pos: Vector2) -> float:
	var freq: float = sea_freq
	var amp: float = sea_height
	var choppy: float = sea_choppy
	# Precompute time offset once (same xy used)
	var time_offset: Vector2 = Vector2(current_time * sea_speed, current_time * sea_speed)
	var uv: Vector2 = world_pos
	uv.x *= 0.75
	var h: float = 0.0
	for i in range(3):   # ITER_GEOMETRY
		# First octave
		var d: float = sea_octave((uv + time_offset) * freq, choppy)
		# Second octave
		d += sea_octave((uv - time_offset) * freq, choppy)
		h += d * amp
		# Inlined 2x2 matrix multiplication: OCTAVE_M = [[1.6, 1.2], [-1.2, 1.6]]
		var new_x: float = 1.6 * uv.x + 1.2 * uv.y
		var new_y: float = -1.2 * uv.x + 1.6 * uv.y
		uv = Vector2(new_x, new_y)
		freq *= 1.9
		amp *= 0.22
		choppy = lerp(choppy, 1.0, 0.2)
	return h
