extends Node3D

@onready var bouy: 				PackedScene = load("res://scene/objects/bouy.tscn")
@onready var pillar: 			PackedScene = load("res://scene/objects/pillar.tscn")
var last_center_point:			= Vector2.ZERO
var min_bouy_distance: 			float = 4.0
var track_width: 				float = 30.0									# width in meters


func _ready() -> void:
	var track_data: racetrack.track_data = racetrack.generate_track(
		racetrack.config.new(
			20,																	# num_points
			250.0,																# margin
			300.0,																# min_distance
			500.0,																# connect_distance
			0,																	# num_splits
			-1,																	# random_seed
			Vector2(600.0, 600.0))												# area_rect
	)
	
	var spline_points: Array[Vector2] = track_data.spline_points as Array[Vector2]
	if spline_points.is_empty():
		return

	var open: bool = track_data.open          # true when track is NOT closed
	var n := spline_points.size()
	var tangents := compute_tangents(spline_points)
	var half_width := track_width * 0.5

	# Pre‑compute left and right edge points for every spline point
	var left_edges: Array[Vector2]  = []
	var right_edges: Array[Vector2] = []
	for i in range(n):
		var tangent := tangents[i]
		var perp := Vector2(-tangent.y, tangent.x)
		var center := spline_points[i]
		left_edges.append(center + perp * half_width)
		right_edges.append(center - perp * half_width)

	var quads: Array[PackedVector2Array] = []									# Build quadrilaterals for each track segment, a segment is the area between spline_points[i] and spline_points[i+1]
	if not open:
		for i in range(n):
			var j := (i + 1) % n
			quads.append(PackedVector2Array([
				left_edges[i],  right_edges[i],
				right_edges[j], left_edges[j]
			]))
	else:
		for i in range(n - 1):
			var j := i + 1
			quads.append(PackedVector2Array([
				left_edges[i],  right_edges[i],
				right_edges[j], left_edges[j]
			]))


	var m := track_data.track_path.size()
	for k in range(m):
		var point := track_data.track_path[k]
		var tangent: Vector2 = Vector2.RIGHT   # fallback, no direction available
		if m != 1:
			var prev_point: Vector2
			var next_point: Vector2
			if track_data.open:
				prev_point = track_data.track_path[max(k - 1, 0)]
				next_point = track_data.track_path[min(k + 1, m - 1)]
				if k == 0:
					tangent = (track_data.track_path[1] - point).normalized()
				elif k == m - 1:
					tangent = (point - track_data.track_path[m - 2]).normalized()
				else:
					tangent = (next_point - prev_point).normalized()
			else:  # closed track
				prev_point = track_data.track_path[(k - 1) % m]
				next_point = track_data.track_path[(k + 1) % m]
				tangent = (next_point - prev_point).normalized()
		
		var perp := Vector2(-tangent.y, tangent.x)
		var left_edge  := point + perp * half_width
		var right_edge := point - perp * half_width
		spawn_pillar_at(left_edge)
		spawn_pillar_at(right_edge)
		last_center_point = point   # still use center for buoy distance skipping


	for i in range(n):															# Place buoys, skipping those that fall inside another segment
		var center := spline_points[i]
		if center.distance_squared_to(last_center_point) < min_bouy_distance * min_bouy_distance:	# Distance skip (same as before)
			continue

		var left_buoy  := left_edges[i]
		var right_buoy := right_edges[i]
		var left_ok  := true
		var right_ok := true

		for j in range(quads.size()):											# Check overlap with every segment except the immediate neighbours
			if not open:
				var d := wrapi(j - i, -n/2, n/2)								# Closed track – skip indices i‑2 to i+2 (wrapping safe)
				if abs(d) <= 2:
					continue
			else:
				if j >= i - 2 and j <= i + 1:									# Open track – skip segment indices that share point i or its neighbours
					continue

			var quad := quads[j]
			if left_ok and Geometry2D.is_point_in_polygon(left_buoy, quad):
				left_ok = false
			if right_ok and Geometry2D.is_point_in_polygon(right_buoy, quad):
				right_ok = false
			if not left_ok and not right_ok:
				break

		if left_ok:
			spawn_buoy_at(left_buoy)
		if right_ok:
			spawn_buoy_at(right_buoy)

		if left_ok or right_ok:
			last_center_point = center


func compute_tangents(points: Array[Vector2]) -> Array[Vector2]:
	var n := points.size()
	var tangents: Array[Vector2] = []
	for i in range(n):
		var prev: Vector2 = points[(i - 1) % n]
		var next: Vector2 = points[(i + 1) % n]
		var dir: Vector2 = (next - prev).normalized()
		tangents.append(dir)
	return tangents


func spawn_buoy_at(world_pos_2d: Vector2) -> void:
	var bouy_instance := bouy.instantiate()
	bouy_instance.set_spawn_location(Vector3(world_pos_2d.x, 60.0, world_pos_2d.y))
	add_child(bouy_instance)


func spawn_pillar_at(world_pos_2d: Vector2) -> void:
	var pillar_instance := pillar.instantiate()
	pillar_instance.set_spawn_location(Vector3(world_pos_2d.x, 60.0, world_pos_2d.y))
	add_child(pillar_instance)

































	
