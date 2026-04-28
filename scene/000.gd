extends Node3D

var bouy: PackedScene
var last_center_point := Vector2.ZERO
var min_bouy_distance: float = 4.0
var track_width: float = 20.0   # total width in meters


func _ready() -> void:
	bouy = load("res://scene/objects/bouy.tscn")
	var track_data: racetrack.track_data = racetrack.generate_track(
		racetrack.config.new(18, 80.0, 100.0, 500.0, 0, -1, Vector2(300.0, 300.0))
	)
	var spline_points: Array[Vector2] = track_data.spline_points as Array[Vector2]
	if spline_points.is_empty():
		return

	var open: bool = track_data.open          # true when track is NOT closed
	var n := spline_points.size()
	var tangents := compute_tangents(spline_points)
	var half_width := track_width * 0.5

	# 1) Pre‑compute left and right edge points for every spline point
	var left_edges: Array[Vector2]  = []
	var right_edges: Array[Vector2] = []
	for i in range(n):
		var tangent := tangents[i]
		var perp := Vector2(-tangent.y, tangent.x)
		var center := spline_points[i]
		left_edges.append(center + perp * half_width)
		right_edges.append(center - perp * half_width)

	# 2) Build quadrilaterals for each track segment
	#    A segment is the area between spline_points[i] and spline_points[i+1]
	var quads: Array[PackedVector2Array] = []
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

	# 3) Place buoys, skipping those that fall inside another segment
	for i in range(n):
		var center := spline_points[i]

		# Distance skip (same as before)
		if center.distance_squared_to(last_center_point) < min_bouy_distance * min_bouy_distance:
			continue

		var left_buoy  := left_edges[i]
		var right_buoy := right_edges[i]

		var left_ok  := true
		var right_ok := true

		# Check overlap with every segment except the immediate neighbours
		for j in range(quads.size()):
			if not open:
				# Closed track – skip indices i‑2 to i+2 (wrapping safe)
				var d := wrapi(j - i, -n/2, n/2)
				if abs(d) <= 2:
					continue
			else:
				# Open track – skip segment indices that share point i or its neighbours
				# (segment j goes from j to j+1)
				if j >= i - 2 and j <= i + 1:
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
	add_child(bouy_instance)
	bouy_instance.position = Vector3(world_pos_2d.x, 2.0, world_pos_2d.y)
