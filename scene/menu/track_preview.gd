extends TextureRect

var track_data_resource : racetrack.track_data = null



func set_track(track: racetrack.track_data) -> void:
	track_data_resource = track
	queue_redraw()   # forces a redraw


func _draw() -> void:
	if track_data_resource == null:
		return
	var spline: Array[Vector2] = track_data_resource.spline_points
	if spline.size() < 2:
		return

	# Find world bounds (min/max of all points)
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for p in spline:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	var world_width := max_x - min_x
	var world_height := max_y - min_y
	if world_width == 0 or world_height == 0:
		return

	# Determine scale to fit inside our control (with a margin)
	var margin := 10.0
	var target_rect := Rect2(Vector2(margin, margin),
							 size - Vector2(margin, margin) * 2)
	var scale_x := target_rect.size.x / world_width
	var scale_y := target_rect.size.y / world_height
	var scale: float = min(scale_x, scale_y)

	# Offset to centre the track
	var offset := target_rect.position + Vector2(
		(target_rect.size.x - world_width * scale) / 2,
		(target_rect.size.y - world_height * scale) / 2
	) - Vector2(min_x, min_y) * scale

	# Draw the spline as a polyline
	var screen_points: Array[Vector2] = []
	for p in spline:
		screen_points.append(offset + p * scale)
	draw_polyline(screen_points, Color.WHITE, 2.0, true)

	# Optional: draw control points (red)
	if track_data_resource.track_path:
		for cp in track_data_resource.track_path:
			var screen_cp := offset + cp * scale
			draw_circle(screen_cp, 3.0, Color.RED)



	
