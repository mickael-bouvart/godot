extends KinematicBody2D

const DRIVE_SPEED = 800

signal signal_dead

var _power = 2
var _knock_down = true
var _sound_playing
var _limit_left
var _limit_right
var _detached
var _spawner = null
var _deadsignal_receiver = null
var _deadsignal_callback = null

export var char_walk_speed = 100

var char3_2_preload = preload("res://scenes/char3_2.tscn")

var _velocity = Vector2()
var _current_left

func _ready():
	_sound_playing = false
	_detached = false
	var pos = get_pos()
	_limit_left = -500
	_limit_right = 1960 + 500
	update_current_left()
	_velocity = Vector2(-DRIVE_SPEED * _current_left, 0)
	get_node("anim").play("drive_bike")
	set_fixed_process(true)
	pass

func _fixed_process(delta):
	var pos = get_pos()
	var hero1 = get_tree().get_root().get_node("Main/hero1")
	var hero1_pos = hero1.get_pos()
	
	if abs(hero1_pos.x - pos.x) < 500 && !_sound_playing:
		_sound_playing = true
		get_node("sound").play("motorbike")
	if abs(hero1_pos.x - pos.x) >= 500:
		_sound_playing = false

	#print(str(pos.x) + ", " + str(_limit_left))
	if _current_left == 1 && pos.x < _limit_left:
		if _detached:
			emit_signal("signal_dead", self)
			queue_free()
		_current_left = -1
		_velocity.x = DRIVE_SPEED
		set_scale(Vector2(_current_left, 1))
	elif _current_left == -1 && pos.x > _limit_right:
		if _detached:
			emit_signal("signal_dead", self)
			queue_free()
		_current_left = 1
		_velocity.x = -DRIVE_SPEED
		set_scale(Vector2(_current_left, 1))
	
	var force = Vector2(0, globals.GRAVITY)
	# Integrate forces to velocity
	_velocity += force*delta
	# Integrate velocity into motion and move
	var motion = _velocity*delta	
	motion = move(motion)
	if (is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		_velocity = n.slide(_velocity)
		motion = move(motion)
	#var n = get_node("offensive_hitbox_area")
	#print("Monitoring: " + str(n.is_monitoring_enabled()))
	pass

func update_current_left():
	var hero1 = get_tree().get_root().get_node("Main/hero1")
	var new_left = null
	if (get_pos().x < hero1.get_pos().x):
		new_left = -1
	else:
		new_left = 1
	if (new_left != null && new_left != _current_left):
		print("Switching direction: " + str(new_left))
		set_scale(Vector2(new_left, 1))
		_current_left = new_left

func get_hit(power, knock_down):
	if _detached:
		return
	_detached = true
	var char3_2 = char3_2_preload.instance()
	if _spawner != null:
		_spawner.connect_event("signal_dead", char3_2)
	char3_2.connect_dead(_deadsignal_receiver, _deadsignal_callback)
	char3_2.set_pos(get_pos())
	char3_2.set_walk_speed(char_walk_speed)
	if is_in_group("spawned"):
		char3_2.add_to_group("spawned")
	get_node("../").add_child(char3_2)
	char3_2.get_node("sprite").set_modulate(get_node("sprite").get_modulate())
	char3_2.get_hit(power, true)
	#queue_free()
	get_node("sprite").set_texture(load("res://assets/sprites/sprites_char3_1.png"))
	pass

func _on_offensive_hitbox_area_area_enter( area ):
	print("_on_offensive_hitbox_area_area_enter")
	var player = area.get_node("../")
	player.get_hit(_power, _knock_down)
	get_node("sound").play("punch_01")

func set_spawner(spawner):
	_spawner = spawner

func set_char_walk_speed(new_speed):
	char_walk_speed = new_speed

func connect_dead(receiver, callback):
	_deadsignal_receiver = receiver
	_deadsignal_callback = callback