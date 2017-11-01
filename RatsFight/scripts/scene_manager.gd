extends Node

onready var _node_anim = get_node("anim")

func _ready():
	pass

func change_scene(new_scene):
	_node_anim.play("fade_in")
	yield(_node_anim, "finished")
	print(new_scene)
	get_tree().change_scene(new_scene)
	
	_node_anim.play("fade_out")