extends KinematicBody2D

signal signal_dead

onready var _node_parent = get_node("../")
onready var _node_defensive_hitbox_area = get_node("defensive_hitbox_area")
onready var _node_anim = get_node("anim")

var _preload_bullet = preload("res://scenes/bullet.tscn")

const FLOOR_ANGLE_TOLERANCE = 40
const MAX_HP = 20
const WALK_SPEED = 400
const GRAVITY = 500.0

enum STATE {
	HIT,
	WALK,
	BEING_HIT,
	IDLE,
	KO
}

var _current_left = -1
var _hp
var _velocity
var _state

func _ready():
	_state = STATE.IDLE
	_node_anim.play("stand")
	_hp = MAX_HP
	_velocity = Vector2(0, 0)
	set_fixed_process(true)

var _hit_time_cnt = 0
const TIME_LIMIT = 4

func _fixed_process(delta):
	if _state == STATE.IDLE:
		_velocity.x = 0
		update_current_left()
		_hit_time_cnt += delta
		if _hit_time_cnt > TIME_LIMIT:
			_hit_time_cnt = 0
			_state = STATE.HIT
			get_node("anim").play("hit_01")
	apply_forces(delta)

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

func apply_forces(delta):
	var force = Vector2(0, GRAVITY)
	# Integrate forces to velocity
	_velocity += force * delta
	# Integrate velocity into motion and move
	var motion = _velocity * delta
	motion = move(motion)
	
	if (is_colliding()):
		var n = get_collision_normal()
		# touch the floor
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
			if [STATE.BEING_HIT, STATE.KO, STATE.IDLE, STATE.HIT].has(_state):
				motion.x = 0
		
		if ![STATE.BEING_HIT, STATE.KO].has(_state):
			motion = n.slide(motion)
			_velocity = n.slide(_velocity)
		motion = move(motion)

func shoot():
	var bullet = _preload_bullet.instance()
	bullet.set_pos(get_pos() + Vector2(-_current_left * 160, 10))
	_node_parent.add_child(bullet)
	bullet.set_velocity(_current_left)

func get_hit(power, knock_down):
	_velocity = Vector2(0, 0)
	_hp -= power
	if (_hp <= 0):
		_velocity = Vector2(_current_left * WALK_SPEED, -200)
		_node_defensive_hitbox_area.set_monitorable(false)
		_node_anim.play("ko")
		_state = STATE.KO
	elif !knock_down:
		_node_anim.play("being_hit")
		_state = STATE.BEING_HIT
	else:
		_node_defensive_hitbox_area.set_monitorable(false)
		_velocity = Vector2(_current_left * WALK_SPEED, -200)
		_state = STATE.BEING_HIT
		get_node("anim").play("knock_down")

func recovered_hit():
	_node_anim.play("stand")
	_state = STATE.IDLE

func end_hit():
	_node_anim.play("stand")
	_state = STATE.IDLE

func get_up():
	_node_defensive_hitbox_area.set_monitorable(true)
	_node_anim.play("stand")
	_state = STATE.IDLE

func dead():
	emit_signal("signal_dead", self)
	queue_free()