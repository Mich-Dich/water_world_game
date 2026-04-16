extends ColorRect

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var bu_quit: Button = find_child("bu_quit")
@onready var bu_resume: Button = find_child("bu_resume")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	bu_resume.pressed.connect(resume)
	bu_quit.pressed.connect(get_tree().quit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func resume():
	animator.play("hide")
	self.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false;
	print("Resuming Game")


func pause():
	animator.play("show")
	self.show()
	get_tree().paused = true;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("Pausing Game")
