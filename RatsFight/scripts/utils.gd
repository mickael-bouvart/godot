extends Node

func _ready():
	pass

func get_hero1():
	return get_tree().get_root().get_node("Main/hero1")

func get_camera():
	return get_hero1().get_node("camera")

func shake_camera(magnitude, duration):
	get_camera().shake(magnitude, duration)

func is_input_action_pressed(p, action):
	return Input.is_action_pressed(p + "_" + action)

func switch_menu(current_menu, new_menu_path):
	var new_menu_load = load(new_menu_path)
	var new_menu = new_menu_load.instance()
	current_menu.hide()
	current_menu.get_node("../").add_child(new_menu)
	current_menu.queue_free()