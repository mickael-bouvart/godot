extends Node

export var bgm = ""

const CAMERA_SCROLL_SPEED = 5

onready var _node_camera = get_node("hero1/camera")
onready var _node_right_border = get_node("borders/right_border")
onready var _node_swarms = get_node("swarms")

var _camera_limit
var _swarms
var _current_swarm

func _ready():
	bgms.play(bgm)
	_current_swarm = -1
	_swarms = _node_swarms.get_children()
	var bg_tex = get_node("background").get_texture()
	var cam_margin_right = bg_tex.get_width()
	var cam_margin_bottom = bg_tex.get_height()
	_camera_limit = _node_right_border.get_pos().x
	_node_camera.set_limit(MARGIN_RIGHT, _camera_limit)
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
		get_node(path).connect("signal_clear", self, "next_step")
		_camera_limit = get_node(path).get_camera_limit()
		print("Camera limit: " + str(_camera_limit))
		_node_right_border.set_pos(Vector2(_camera_limit, _node_right_border.get_pos().y))

func _fixed_process(delta):
	if _node_camera.get_limit(MARGIN_RIGHT) < _camera_limit:
		_node_camera.set_limit(MARGIN_RIGHT, _node_camera.get_limit(MARGIN_RIGHT) + CAMERA_SCROLL_SPEED)
	if (Input.is_action_pressed("reset_scene")):
		get_tree().reload_current_scene()