extends Node
const CAMERA_SCROLL_SPEED = 5

onready var _camera = get_node("hero1").get_node("camera")

var camera_limit
var swarms
var current_swarm

func _ready():
	current_swarm = -1
	swarms = get_node("swarms").get_children()
	var bg_tex = get_node("background").get_texture()
	var cam_margin_right = bg_tex.get_width()
	var cam_margin_bottom = bg_tex.get_height()
	camera_limit = get_node("right_border").get_pos().x
	_camera.set_limit(MARGIN_RIGHT, camera_limit)
	_camera.set_limit(MARGIN_BOTTOM, cam_margin_bottom)
	set_fixed_process(true)
	next_step()

func next_step():
	print("NEXT STEP")
	current_swarm += 1
	if current_swarm < swarms.size():
		var new_swarm = swarms[current_swarm]
		var path = new_swarm.get_path()
		new_swarm.replace_by_instance()
		get_node(path).connect("signal_clear", self, "next_step")
		camera_limit = get_node(path).get_camera_limit()
		print("Camera limit: " + str(camera_limit))
		get_node("right_border").set_pos(Vector2(camera_limit, get_node("right_border").get_pos().y))
		#print(new_swarm)

func _fixed_process(delta):
	if _camera.get_limit(MARGIN_RIGHT) < camera_limit:
		_camera.set_limit(MARGIN_RIGHT, _camera.get_limit(MARGIN_RIGHT) + CAMERA_SCROLL_SPEED)
	var reset = Input.is_action_pressed("reset_scene")
	if (reset):
		get_tree().reload_current_scene()