extends Node3D

var bouy: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bouy = load("res://scene/objects/bouy.tscn")
	var track_data := racetrack.generate_track({
		num_points = 18,
		margin = 80,
		min_dist = 120,
		connect_dist = 400,
		num_splits = 0,
		seed = -1,
		area_rect = Vector2(400, 400)
	})
	for point in track_data.spline_points:
		spawn_debug_cylinder(point)


func spawn_debug_cylinder(point: Vector2) -> void:
	var bouy_instance := bouy.instantiate()
	add_child(bouy_instance)
	bouy_instance.position = Vector3(point.x, 2.0, point.y)
