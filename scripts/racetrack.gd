extends Node

const MAX_RETRIES: int = 10
const MAX_ATTEMPTS: int = 100
const SPLINE_SAMPLES: int = 20
const MIN_TRACK_LENGTH: int = 8

class config:
	var num_points: int
	var margin: float
	var min_distance: float
	var connect_distance: float
	var num_splits: int
	var random_seed: int
	var area_rect: Vector2
	
	func _init(p_num_points: int, p_margin: float, p_min_distance: float, p_connect_distance: float, 
		p_num_splits: int, p_seed: int = -1, p_area_rect: Vector2 = Vector2(500, 500)) -> void:
		num_points = p_num_points
		margin = p_margin
		min_distance = p_min_distance
		connect_distance = p_connect_distance
		num_splits = p_num_splits
		random_seed = p_seed
		area_rect = p_area_rect

var default_config := config.new(15, 50.0, 5000.0, 400.0, 1, 42, Vector2(300.0, 300.0))

class track_data:
	var control_points: Array[Vector2]
	var track_path: Array[Vector2]
	var open: bool
	var spline_points: Array[Vector2]
	var splits: Array[Vector2]
	
	func _init(p_control_points: Array[Vector2], p_track_path: Array[Vector2], p_open: bool,
		p_spline_points: Array[Vector2], p_splits: Array[Vector2]) -> void:
		control_points = p_control_points
		track_path = p_track_path
		open = p_open
		spline_points = p_spline_points
		splits = p_splits

var current_track: track_data



func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func generate_track(local_config: config = default_config) -> track_data:
	var random := RandomNumberGenerator.new()
	if local_config.random_seed != -1:
		random.seed = local_config.random_seed
	var open: bool = true
	var counter: int = 0
	var points: Array[Vector2] = []
	var path: Array[Vector2] = []
	while open and counter < MAX_ATTEMPTS:				# repeat untill track makes sense
		points = generate_points(random, local_config)
		path = build_track_path(points, local_config.connect_distance)
		open = (path.size() < MIN_TRACK_LENGTH) or (path[0] != path.back())
		counter += 1
	print("Created track with [", counter, "] attempts, track open: [", open, "]")

	path.pop_back()
	var spline_points: Array[Vector2] = get_spline_points(path, !open, SPLINE_SAMPLES)
	var splits: Array[Vector2] = []
	if local_config.num_splits > 0 and path.size() >= 3:
		splits = create_splits(path, local_config.num_splits, local_config.area_rect)
	current_track = track_data.new(points, path, open, spline_points, splits)
	return current_track


func get_spline_points(control_points: Array[Vector2], closed: bool = false, num_samples: int = SPLINE_SAMPLES) -> Array[Vector2]:
	if control_points.size() < 2:
		return control_points.duplicate()
	if control_points.size() == 2:
		var result := [control_points[0]]
		for i in range(1, num_samples):
			result.append(control_points[0].lerp(control_points[1], float(i) / num_samples))
		result.append(control_points[1])
		return result

	var spline: Array[Vector2] = []
	if closed:
		var n := control_points.size()
		for i in range(n):
			var p0: Vector2 = control_points[(i - 1) % n]
			var p1: Vector2 = control_points[i]
			var p2: Vector2 = control_points[(i + 1) % n]
			var p3: Vector2 = control_points[(i + 2) % n]
			var d_prev := pow(p1.distance_to(p0), 0.5)
			var d_curr := pow(p2.distance_to(p1), 0.5)
			var d_next := pow(p3.distance_to(p2), 0.5)
			var t1 := 0.0
			var t0 := t1 - d_prev
			var t2 := t1 + d_curr
			var t3 := t2 + d_next
			for j in range(num_samples):
				var t := t1 + (t2 - t1) * (float(j) / num_samples)
				spline.append(centripetal_catmull_rom_point(p0, p1, p2, p3, t0, t1, t2, t3, t))
		spline.append(spline[0])   # close smooth loop
	else:
		var extended := [control_points[0]] + control_points + [control_points.back()]
		for i in range(1, extended.size() - 1):
			var p0: Vector2 = extended[i - 1]
			var p1: Vector2 = extended[i]
			var p2: Vector2 = extended[i + 1]
			var p3: Vector2 = extended[i + 2]
			var d_prev := pow(p1.distance_to(p0), 0.5)
			var d_curr := pow(p2.distance_to(p1), 0.5)
			var d_next := pow(p3.distance_to(p2), 0.5)
			var t1 := 0.0
			var t0 := t1 - d_prev
			var t2 := t1 + d_curr
			var t3 := t2 + d_next
			for j in range(num_samples):
				var t := t1 + (t2 - t1) * (float(j) / num_samples)
				spline.append(centripetal_catmull_rom_point(p0, p1, p2, p3, t0, t1, t2, t3, t))
		spline.append(control_points.back())
	return spline


func create_splits(track_control_points: Array, num_splits: int, area_rect: Vector2) -> Array:
	if num_splits <= 0 or track_control_points.size() < 3:
		return []
	var n := track_control_points.size()
	var edges := []
	for i in range(n):
		var p1: Vector2 = track_control_points[i]
		var p2: Vector2 = track_control_points[(i + 1) % n]
		var length := p1.distance_to(p2)
		edges.append({"index": i, "length": length})
	var avg_len := 0.0
	for edge: Dictionary in edges:
		avg_len += edge.length
	avg_len /= n

	# sort edges by how close their length is to the average
	edges.sort_custom(func(a, b): return abs(a.length - avg_len) < abs(b.length - avg_len))
	var available := range(n)
	var splits := []
	for edge: Dictionary in edges:
		var idx: int = edge.index
		if idx not in available or edge.length < 30:
			continue
		available.erase(idx)
		available.erase(wrapi(idx - 1, 0, n))
		available.erase(wrapi(idx + 1, 0, n))

		var p_start: Vector2 = track_control_points[idx]
		var p_end: Vector2 = track_control_points[(idx + 1) % n]
		var mid := (p_start + p_end) * 0.5
		var dx := p_end.x - p_start.x
		var dy := p_end.y - p_start.y
		var length_actual := sqrt(dx * dx + dy * dy)
		if length_actual == 0:
			continue
		var perp := Vector2(-dy / length_actual, dx / length_actual)
		var offset := length_actual * 0.3

		# clamp mid points inside the area (with a margin of 50, or use area_rect bounds)
		var left := area_rect.x + 50
		var right := area_rect.x - 50
		var top := area_rect.y + 50
		var bottom := area_rect.y - 50
		var mid1 := mid + perp * offset
		var mid2 := mid - perp * offset
		mid1 = Vector2(clamp(mid1.x, left, right), clamp(mid1.y, top, bottom))
		mid2 = Vector2(clamp(mid2.x, left, right), clamp(mid2.y, top, bottom))
		splits.append({
			"start": p_start,
			"end": p_end,
			"mid1": mid1,
			"mid2": mid2
		})
		if splits.size() >= num_splits:
			break
	return splits


func centripetal_catmull_rom_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, 
	t0: float, t1: float, t2: float, t3: float, t: float) -> Vector2:
	var A1 := p0.lerp(p1, (t - t0) / (t1 - t0) if t1 != t0 else 0.0)
	var A2 := p1.lerp(p2, (t - t1) / (t2 - t1) if t2 != t1 else 0.0)
	var A3 := p2.lerp(p3, (t - t2) / (t3 - t2) if t3 != t2 else 0.0)
	var B1 := A1.lerp(A2, (t - t0) / (t2 - t0) if t2 != t0 else 0.0)
	var B2 := A2.lerp(A3, (t - t1) / (t3 - t1) if t3 != t1 else 0.0)
	return B1.lerp(B2, (t - t1) / (t2 - t1) if t2 != t1 else 0.0)


func build_track_path(points: Array[Vector2], max_distance: float) -> Array[Vector2]:
	if points.is_empty():
		return []

	var unvisited: Array = range(points.size())
	var current_index: int = unvisited.pop_front()
	var current:= points[current_index] as Vector2
	var path: Array[Vector2] = [current]
	while not unvisited.is_empty():
		var nearest_index: int = -1
		var nearest_dist: float = INF
		for index: int in unvisited:
			var d: float = current.distance_to(points[index])
			if d < nearest_dist:
				nearest_dist = d
				nearest_index = index
		if nearest_dist <= max_distance and nearest_index != -1:
			current = points[nearest_index]
			path.append(current)
			unvisited.erase(nearest_index)
		else:
			break
	
	if path.size() > 2:
		var d_to_start: float = path.back().distance_to(path[0])
		if d_to_start <= max_distance:
			path.append(path[0])
	return path


func generate_points(random: RandomNumberGenerator, local_config: config = default_config) -> Array[Vector2]:
	#var margin: float = local_config.margin
	var min_distance: float = local_config.min_distance
	var area_rect: Vector2 = local_config.area_rect
	var x_min: float = -area_rect.x
	var x_max: float = area_rect.x
	var y_min: float = -area_rect.y
	var y_max: float = area_rect.y
	var candidate: Array[Vector2] = []
	for _i in range(local_config.num_points):
		var best_pt := Vector2.ZERO
		var best_min_dist := -1.0
		for _trial in range(MAX_ATTEMPTS):
			var x := random.randf_range(x_min, x_max)
			var y := random.randf_range(y_min, y_max)
			var valid := true
			var min_d := INF
			for pt in candidate:
				var d := Vector2(x, y).distance_to(pt)
				if d < min_distance:
					valid = false
					if d < min_d:
						min_d = d
			if valid:
				best_pt = Vector2(x, y)
				break
			else:
				if min_d > best_min_dist:
					best_min_dist = min_d
					best_pt = Vector2(x, y)
		candidate.append(best_pt)
	return candidate




































	
