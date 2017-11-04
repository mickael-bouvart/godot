extends Node

var _keyboard_start = false
var _keyboard_ready = false
var _joypad_start = false
var _joypad_ready = false
var _joypad2_start = false
var _joypad2_ready = false
var _validated = 0

var _control_to_player = {}

func _ready():
	bgms.play("rock_intro")
	globals.set_nb_players(0)
	get_node("p1_anim").play("blink")
	get_node("p2_anim").play("blink")
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("keyboard_start"):
		if !_keyboard_start:
			_keyboard_start = true
			add_player("keyboard")
		elif !_keyboard_ready:
			_keyboard_ready = true
			validate("keyboard")
	elif event.is_action_pressed("joypad_start"):
		if !_joypad_start:
			_joypad_start = true
			add_player("joypad")
		elif !_joypad_ready:
			_joypad_ready = true
			validate("joypad")
	elif event.is_action_pressed("joypad2_start"):
		if !_joypad2_start:
			_joypad2_start = true
			add_player("joypad2")
		elif !_joypad2_ready:
			_joypad2_ready = true
			validate("joypad2")

func validate(control):
	_validated += 1
	var p = _control_to_player[control]
	get_node("sprite_select_p%d" % p).hide()
	if globals.get_nb_players() == _validated:
		game_start()

func game_start():
	scene_manager.change_scene("res://stages/stage_01/stage_01.tscn")

func add_player(control):
	var nb_player = globals.get_nb_players() + 1
	globals.set_nb_players(nb_player)
	get_node("p%d_anim" % nb_player).stop()
	get_node("p%d_press_start" % nb_player).hide()
	get_node("sprite_select_p%d" % nb_player).show()
	_control_to_player[control] = nb_player

	if nb_player == 1:
		globals.set_p1_control(control)
	else:
		globals.set_p2_control(control)