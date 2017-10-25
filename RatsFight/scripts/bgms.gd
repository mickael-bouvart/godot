extends Node

var _current_bgm

func _ready():
	_current_bgm = null

func play(music):
	if _current_bgm == music:
		return
	if _current_bgm != null:
		get_node(_current_bgm).stop()
	_current_bgm = music
	get_node(_current_bgm).play()