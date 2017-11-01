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