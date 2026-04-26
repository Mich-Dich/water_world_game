extends Node3D

var bouy: PackedScene
var last_center_point := Vector2.ZERO
var min_bouy_distance: float = 4.0
var track_width: float = 20.0   # total width in meters


func _ready() -> void:
	bouy = load("res://scene/objects/bouy.tscn")
	var track_data: racetrack.track_data = racetrack.generate_track(racetrack.config.new(18, 80.0, 100.0, 500.0, 0, -1, Vector2(300.0, 300.0)))
	var spline_points: Array[Vector2] = track_data.spline_points as Array[Vector2]
	if spline_points.is_empty():
		return
	var tangents: Array[Vector2] = compute_tangents(spline_points)				# Compute tangents for every spline point
	for i in range(spline_points.size()):										# Place buoys along the track
		var center: Vector2 = spline_points[i]
		if center.distance_to(last_center_point) >= min_bouy_distance:
			var tangent := tangents[i]
			var perp := Vector2(-tangent.y, tangent.x)							# Perpendicular: rotate tangent 90°
			var half_width := track_width * 0.5
			var left_pos := center + perp * half_width
			var right_pos := center - perp * half_width
			spawn_buoy_at(left_pos)
			spawn_buoy_at(right_pos)
			last_center_point = center


func compute_tangents(points: Array[Vector2]) -> Array[Vector2]:
	var n := points.size()
	var tangents: Array[Vector2] = []
	for i in range(n):
		var prev: Vector2= points[(i - 1) % n]
		var next: Vector2 = points[(i + 1) % n]
		var dir: Vector2 = (next - prev).normalized()
		tangents.append(dir)
	return tangents


func spawn_buoy_at(world_pos_2d: Vector2) -> void:
	var bouy_instance := bouy.instantiate()
	add_child(bouy_instance)
	bouy_instance.position = Vector3(world_pos_2d.x, 2.0, world_pos_2d.y)
