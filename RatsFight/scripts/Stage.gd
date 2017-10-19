extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	get_node("char1").get_node("camera").set_limit(MARGIN_LEFT, 0)
	var cam_margin_right = get_node("background").get_texture().get_width()
	get_node("char1").get_node("camera").set_limit(MARGIN_RIGHT, cam_margin_right)
	set_fixed_process(true)
	
func _fixed_process(delta):
	var reset = Input.is_action_pressed("reset_scene")
	if (reset):
		get_tree().reload_current_scene()