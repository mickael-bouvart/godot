extends Node

const FADE_OUT_SPEED = 0.01

var _current_bgm
var _fade_out_volume
var _next_bgm

func _ready():
	_current_bgm = null
	_fade_out_volume = null
	_next_bgm = null
	set_fixed_process(true)

func play(music):
	if music == null || music == "" || _current_bgm == music:
		return
	if _current_bgm == null:
		_current_bgm = music
		get_node(_current_bgm).play()
	else:
		_fade_out_volume = get_node(_current_bgm).get_volume()
		print("VOLUME: " + str(_fade_out_volume))
		_next_bgm = music

func stop():
	_fade_out_volume = get_node(_current_bgm).get_volume()
	_next_bgm = null

func _fixed_process(delta):
	if _fade_out_volume != null && _fade_out_volume > 0:
		_fade_out_volume -= FADE_OUT_SPEED
		get_node(_current_bgm).set_volume(_fade_out_volume)
	if _fade_out_volume != null && _fade_out_volume <= 0:
		_fade_out_volume = null
		_current_bgm = _next_bgm
		if _current_bgm != null && _current_bgm != "":
			get_node(_current_bgm).play()
			get_node(_current_bgm).set_volume(1)