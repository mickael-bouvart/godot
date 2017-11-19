extends Node

export (PackedScene) var _stage = null

func _ready():
	pass

func _on_timer_timeout():
	scene_manager.change_scene(_stage.get_path())