extends Node

const MAX_SPAWNS = 2

var preload_char3 = preload("res://scenes/char3.tscn")
var _spawn_cnt
var _spawn_time_cnt
const SPAWN_INTERVAL = 5

func _ready():
	_spawn_cnt = 0
	_spawn_time_cnt = 0
	set_fixed_process(true)
	pass

func _fixed_process(delta):
	if _spawn_cnt < MAX_SPAWNS:
		_spawn_time_cnt += delta
		if _spawn_time_cnt > SPAWN_INTERVAL:
			_spawn_time_cnt = 0
			_spawn_cnt += 1
			spawn()

func spawn():
	var char3 = preload_char3.instance()
	char3.set_spawner(self)
	char3.set_char_walk_speed(300)
	var left = randi() % 2 == 0
	if left:
		char3.set_pos(Vector2(-500, 300))
	else:
		char3.set_pos(Vector2(2500, 300))
	get_node("../").add_child(char3)

func connect_event(signal_name, object):
	object.connect(signal_name, self, "on_char3_2_dead")

func on_char3_2_dead(char):
	_spawn_cnt -= 1

func get_hit(power, knock_down):
	queue_free()