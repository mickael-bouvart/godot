extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var _camera = get_node("hero1").get_node("camera")

func _ready():
	_camera.set_limit(MARGIN_LEFT, 0)
	var cam_margin_right = get_node("background").get_texture().get_width()
	_camera.set_limit(MARGIN_RIGHT, cam_margin_right)
	_camera.set_limit(MARGIN_BOTTOM, 560)
	set_fixed_process(true)
	
func _fixed_process(delta):
	var reset = Input.is_action_pressed("reset_scene")
	if (reset):
		get_tree().reload_current_scene()