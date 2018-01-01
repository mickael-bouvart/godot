extends Node

var _keyboard_start = false
var _keyboard_ready = false
var _joypad_start = false
var _joypad_ready = false
var _joypad2_start = false
var _joypad2_ready = false
var _validated = 0
var _start_timer = 0

var _control_to_player = {}
var _player_hero = { 1: 1, 2: 2 }

func _ready():
	bgms.play("rock_intro")
	globals.set_nb_players(0)
	get_node("lbl_p1_info").set_text("PRESS START")
	get_node("lbl_p2_info").set_text("PRESS START")
	get_node("p1_anim").play("blink")
	get_node("p2_anim").play("blink")
	set_process_input(true)
	set_fixed_process(true)

func _fixed_process(delta):
	if _start_timer > 0:
		_start_timer -= delta
		if _start_timer <= 0:
			game_start()

func _input(event):
	if event.is_action_pressed("keyboard_start"):
		if !_keyboard_start:
			_keyboard_start = true
			add_player("keyboard")
		elif !_keyboard_ready:
			_keyboard_ready = true
			validate("keyboard")
	elif _keyboard_start && (event.is_action_pressed("keyboard_left") || event.is_action_pressed("keyboard_right")):
		next_character("keyboard")
	elif event.is_action_pressed("joypad_start"):
		if !_joypad_start:
			_joypad_start = true
			add_player("joypad")
		elif !_joypad_ready:
			_joypad_ready = true
			validate("joypad")
	elif _joypad_start && (event.is_action_pressed("joypad_left") || event.is_action_pressed("joypad_right")):
		if (event.type == InputEvent.JOYSTICK_MOTION && abs(event.value) >= 1) || event.type != InputEvent.JOYSTICK_MOTION:
			next_character("joypad")
	elif event.is_action_pressed("joypad2_start"):
		if !_joypad2_start:
			_joypad2_start = true
			add_player("joypad2")
		elif !_joypad2_ready:
			_joypad2_ready = true
			validate("joypad2")
	elif _joypad2_start && (event.is_action_pressed("joypad2_left") || event.is_action_pressed("joypad2_right")):
		if (event.type == InputEvent.JOYSTICK_MOTION && abs(event.value) >= 1) || event.type != InputEvent.JOYSTICK_MOTION:
			next_character("joypad2")

func validate(control):
	_validated += 1
	var p = _control_to_player[control]
	var hero = _player_hero[p]
	if p == 1:
		globals.p1_char = globals.hero1_preload if hero == 1 else globals.hero2_preload
	else:
		globals.p2_char = globals.hero1_preload if hero == 1 else globals.hero2_preload
	get_node("anim_p%d_sprite" % p).play("selected_h%d" % hero)
	get_node("p%d_anim" % p).play("flash_screen")
	get_node("lbl_p%d_info" % p).hide()
	get_node("sprite_select_p%d" % p).hide()
	if globals.get_nb_players() == _validated:
		_start_timer = 2

func next_character(control):
	var p = _control_to_player[control]
	var hero = _player_hero[p]
	get_node("sprite_p%d_h%d" % [p, hero]).hide()
	_player_hero[p] = (_player_hero[p] % 2) + 1
	hero = _player_hero[p]
	var pos = get_node("sprite_hero%d" % hero).get_pos()
	get_node("sprite_select_p%d" % p).set_pos(pos)
	get_node("sprite_p%d_h%d" % [p, hero]).show()
	get_node("anim_p%d_sprite" % p).play("hovered_h%d" % hero)

func game_start():
	globals.init_player_attributes()
	bgms.stop()
	scene_manager.change_scene("res://stages/stage_01/stage_01.tscn")

func add_player(control):
	var instructions_control = "keyboard" if control == "keyboard" else "joypad"
	var nb_player = globals.get_nb_players() + 1
	globals.set_nb_players(nb_player)
	var hero = _player_hero[nb_player]
	get_node("lbl_p%d_info" % nb_player).set_text("CHOOSE CHARACTER")
	get_node("sprite_select_p%d" % nb_player).set_pos(get_node("sprite_hero%d" % hero).get_pos())
	get_node("sprite_select_p%d" % nb_player).show()
	get_node("sprite_p%d_h%d" % [nb_player, hero]).show()
	get_node("anim_p%d_sprite" % nb_player).play("hovered_h%d" % hero)
	get_node("vsplit_instructions/vsplit_p%d_%s_instructions" % [nb_player, instructions_control]).show()
	
	_control_to_player[control] = nb_player

	if nb_player == 1:
		globals.set_p1_control(control)
	else:
		globals.set_p2_control(control)