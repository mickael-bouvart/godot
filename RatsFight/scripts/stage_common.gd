extends Node

export var bgm = ""
export (PackedScene) var next_stage = null

const CAMERA_SCROLL_SPEED = 5


onready var _node_right_border = get_node("borders/right_border")
onready var _node_swarms = get_node("swarms")

var _camera_limit
var _swarms
var _current_swarm
var _node_camera

var plchar1 = preload("res://scenes/char1.tscn")
var plchar2 = preload("res://scenes/char2.tscn")
var plhero1 = preload("res://scenes/hero1.tscn")
	
func _ready():
	var hero1 = plhero1.instance()
	hero1.set_pos(Vector2(200, 0))
	hero1.set_player("p1")
	hero1.set_control(globals.p1_control)
	get_node("heroes").add_child(hero1)
	if globals.nb_players > 1:
		var hero2 = plhero1.instance()
		hero2.set_pos(Vector2(100, 0))
		hero2.set_player("p2")
		hero2.set_control(globals.p2_control)
		get_node("heroes").add_child(hero2)
	get_node("hud").init_hud()
	_node_camera = hero1.get_node("camera")
	_node_camera.make_current()
	bgms.play(bgm)
	_current_swarm = -1
	_swarms = _node_swarms.get_children()
	var bg_tex = get_node("background").get_texture()
	var cam_margin_right = bg_tex.get_width()
	var cam_margin_bottom = bg_tex.get_height()
	#_camera_limit = _node_right_border.get_pos().x
	#_node_camera.set_limit(MARGIN_RIGHT, _camera_limit)
	_node_camera.set_limit(MARGIN_BOTTOM, cam_margin_bottom)
	set_fixed_process(true)
	next_step()

func next_step():
	print("NEXT STEP")
	_current_swarm += 1
	if _current_swarm < _swarms.size():
		var new_swarm = _swarms[_current_swarm]
		var path = new_swarm.get_path()
		new_swarm.replace_by_instance()
		var swarm_instance = get_node(path)
		swarm_instance.connect("signal_clear", self, "next_step")
		bgms.play(swarm_instance.get_bgm())
		_camera_limit = swarm_instance.get_camera_limit()
		print("Camera limit: " + str(_camera_limit))
		_node_right_border.set_pos(Vector2(_camera_limit, _node_right_border.get_pos().y))
	else:
		print("END LEVEL")
		if next_stage != null:
			scene_manager.change_scene(next_stage.get_path())
		else:
			bgms.play("game_over")

func _fixed_process(delta):
	if _node_camera.get_limit(MARGIN_RIGHT) < _camera_limit:
		_node_camera.set_limit(MARGIN_RIGHT, _node_camera.get_limit(MARGIN_RIGHT) + CAMERA_SCROLL_SPEED)
	if _node_camera.get_limit(MARGIN_RIGHT) > _camera_limit:
		_node_camera.set_limit(MARGIN_RIGHT, _camera_limit)
	if (Input.is_action_pressed("reset_scene")):
		get_tree().reload_current_scene()