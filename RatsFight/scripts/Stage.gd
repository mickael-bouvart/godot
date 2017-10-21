extends Node

onready var _camera = get_node("hero1").get_node("camera")

func _ready():
	var bg_tex = get_node("background").get_texture()
	var cam_margin_right = bg_tex.get_width()
	var cam_margin_bottom = bg_tex.get_height()
	_camera.set_limit(MARGIN_RIGHT, cam_margin_right)
	_camera.set_limit(MARGIN_BOTTOM, cam_margin_bottom)
	set_fixed_process(true)

func _fixed_process(delta):
	var reset = Input.is_action_pressed("reset_scene")
	if (reset):
		get_tree().reload_current_scene()