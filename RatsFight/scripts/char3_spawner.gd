extends Node

signal signal_dead

const MAX_SPAWNS = 1
const SPAWN_INTERVAL = 5

var preload_char3 = preload("res://scenes/char3.tscn")
var _spawn_cnt
var _spawn_time_cnt
var _deadsignal_receiver = null
var _deadsignal_callback = null
var _dying

func _ready():
	_dying = 0
	_spawn_cnt = 0
	_spawn_time_cnt = 0
	set_fixed_process(true)
	pass

func _fixed_process(delta):
	if _dying > 0:
		_dying -= delta
		if _dying <= 0:
			emit_signal("signal_dead", self)
			queue_free()
	elif _spawn_cnt < MAX_SPAWNS:
		_spawn_time_cnt += delta
		if _spawn_time_cnt > SPAWN_INTERVAL:
			_spawn_time_cnt = 0
			_spawn_cnt += 1
			spawn()

func spawn():
	var char3 = preload_char3.instance()
	char3.add_to_group("spawned")
	char3.set_spawner(self)
	char3.set_char_walk_speed(300)
	char3.set_char_score(100)
	char3.connect_dead(_deadsignal_receiver, _deadsignal_callback)
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

func get_hit(hero, power, properties):
	_dying = 5

func connect_dead(receiver, callback):
	connect("signal_dead", receiver, callback)
	_deadsignal_receiver = receiver
	_deadsignal_callback = callback