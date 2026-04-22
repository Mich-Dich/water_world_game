extends ColorRect


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	$fps_lable.text = "%d FPS" % Engine.get_frames_per_second()
