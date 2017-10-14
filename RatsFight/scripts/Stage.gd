extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	get_node("char1").get_node("camera").set_limit(MARGIN_LEFT, 0)
	get_node("char1").get_node("camera").set_limit(MARGIN_RIGHT, 1960)
	pass
