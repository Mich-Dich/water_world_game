extends Control

@onready var speed_label: 				= $CenterContainer/speed_label
@onready var RPM_main:					= $CenterContainer/rpm_number_display/rpm_main
@onready var RPM_sub:					= $CenterContainer/rpm_number_display/rpm_sub
@onready var rpm_number_display:		= $CenterContainer/rpm_number_display
@onready var rpm_radial:				= $CenterContainer/rpm_number_display/rpm_green
@onready var fps_lable:					= $PanelContainer2/fps_lable
@export var max_rpm:					int = 6

const speed_text: = "%.1f
KM/H"



func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # Let events pass through
	create_rpm_display(7.0, 5.5)


func create_rpm_display(rpm: float, red_rpm: float) -> void:
	const available_degree: float = 160.0
	var degree_per_main_section: float = available_degree / rpm
	var degree_per_sub_section: float = degree_per_main_section / 10.0
	for index in (rpm +1):
		var RPM_main_duplicate := RPM_main.duplicate(true)
		rpm_number_display.add_child(RPM_main_duplicate)   # ADD THIS
		RPM_main_duplicate.pivot_offset = Vector2(0.125, -4.5)
		RPM_main_duplicate.position = Vector2(-0.25, 95)
		var angle: float = 60.0 + (degree_per_main_section * index)
		RPM_main_duplicate.rotation_degrees = angle
		RPM_main_duplicate.visible = true
		if index > red_rpm:
			RPM_main_duplicate.color = Color(0.901, 0.309, 0.0, 1.0)
		if index != rpm:
			for sub_index in 10:
				var RPM_sub_duplicate := RPM_sub.duplicate()
				rpm_number_display.add_child(RPM_sub_duplicate)   # ADD THIS
				RPM_sub_duplicate.pivot_offset = Vector2(0.13, -15.62)
				RPM_sub_duplicate.position = Vector2(-0.25, 106)
				var sub_angle: float = angle + (degree_per_sub_section * sub_index)
				RPM_sub_duplicate.rotation_degrees = sub_angle
				RPM_sub_duplicate.visible = true
				if (index + (sub_index * 0.1)) > red_rpm:
					RPM_sub_duplicate.color = Color(0.901, 0.309, 0.0, 1.0)


func _process(_delta: float) -> void:
	fps_lable.text = "%d FPS" % Engine.get_frames_per_second()


func on_speed_changed(speed: float) -> void:
	speed_label.text = speed_text % (speed * 3.6)


func on_rpm_changed(rpm_percent: float) -> void:
	rpm_radial.progress = 10.0 + abs(rpm_percent) * 90.0






















	
