extends ColorRect

@onready var animator: 					AnimationPlayer = $AnimationPlayer
@onready var bu_quit: 					Button = find_child("bu_quit")
@onready var bu_resume: 				Button = find_child("bu_resume")
@onready var track_display:				= $track_display_container/MarginContainer/VBoxContainer/track_display
@onready var bu_track_create:			= $HBoxContainer/bu_track_create
@onready var bu_boat_select:			= $HBoxContainer/bu_boat_select
@onready var track_display_container:	= $track_display_container
@onready var boat_selection:			= $boat_selection
signal closing

@onready var spawn_hacker:				= $boat_selection/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/spawn_hacker
@onready var spawn_dragon: 				= $boat_selection/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MarginContainer2/HBoxContainer/VBoxContainer/spawn_dragon

signal spawn_boat_for_player(boat_type: racetrack.boat_types)
enum boat_types {
	DRAGON_SPEED_BOAT,
	HACKER_CRAFT_RUNABOUT
}



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bu_resume.pressed.connect(resume)
	bu_quit.pressed.connect(get_tree().quit)
	bu_track_create.pressed.connect(display_track_creator)
	bu_boat_select.pressed.connect(display_boat_selection)
	
	spawn_hacker.pressed.connect(func(): spawn_boat_for_player.emit(boat_types.HACKER_CRAFT_RUNABOUT))
	spawn_dragon.pressed.connect(func(): spawn_boat_for_player.emit(boat_types.DRAGON_SPEED_BOAT))
	var track_data: racetrack.track_data = racetrack.current_track
	track_display.set_track(track_data)


func _process(_delta: float) -> void:
	pass


func resume() -> void:
	animator.play("hide")
	self.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Resuming Game")
	closing.emit()


func pause() -> void:
	self.show()
	animator.play("show")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("Showing escape settings")


func display_boat_selection() -> void:
	boat_selection.visible = true
	track_display_container.visible = false


func display_track_creator() -> void:
	boat_selection.visible = false
	track_display_container.visible = true



	
