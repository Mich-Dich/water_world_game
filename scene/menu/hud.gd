extends Control

@onready var speed_label: 				= $boat_info/speed_label
@onready var RPM_main:					= $boat_info/rpm_number_display/rpm_main
@onready var RPM_sub:					= $boat_info/rpm_number_display/rpm_sub
@onready var rpm_number_display:		= $boat_info/rpm_number_display
@onready var rpm_radial:				= $boat_info/rpm_number_display/rpm_green
@onready var fps_lable:					= $fps_info/fps_lable
@export var max_rpm:					int = 6

const fps_text: = "%d FPS"
const speed_text: = "%.1f
KM/H"



func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # Let events pass through
	create_rpm_display(7.0, 5.5)


func _process(_delta: float) -> void:
	fps_lable.text = fps_text % Engine.get_frames_per_second()


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
		
		var label_radius: float = 120.0   # adjust this to place label inside/outside the ticks
		var rad_angle: float = deg_to_rad(angle + 90.0)   # +90° if your gauge starts from top, adjust offset
		var label_pos := Vector2(cos(rad_angle), sin(rad_angle)) * label_radius + Vector2(-5.0, -10.0)
		var number_label := Label.new()
		number_label.text = str(int(index))
		number_label.add_theme_font_size_override("font_size", 12)   # adjust size
		number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rpm_number_display.add_child(number_label)
		number_label.position = label_pos

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


func on_speed_changed(speed: float) -> void:
	speed_label.text = speed_text % (speed * 3.6)


func on_rpm_changed(rpm_percent: float) -> void:
	rpm_radial.progress = 10.0 + abs(rpm_percent) * 90.0



































	
