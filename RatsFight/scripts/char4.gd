extends KinematicBody2D

signal signal_dead

onready var _node_parent = get_node("../")
onready var _node_defensive_hitbox_area = get_node("defensive_hitbox_area")
onready var _node_anim = get_node("anim")

var _preload_bullet = preload("res://scenes/bullet.tscn")

const NEAR_THRESHOLD = 50
const FLOOR_ANGLE_TOLERANCE = 40
const MAX_HP = 60
const WALK_SPEED = 1500

const PARAMS = [
	{ "WALK_SPEED": 700, "GRAVITY": 1200.0, "JUMP_FORCE": 800, "KNOCK_DOWN_FORCE": 300, "CAN_JUMP": false },
	{ "WALK_SPEED": 1100, "GRAVITY": 3200.0, "JUMP_FORCE": 1400, "KNOCK_DOWN_FORCE": 500, "CAN_JUMP": false },
	{ "WALK_SPEED": 1500, "GRAVITY": 5000.0, "JUMP_FORCE": 1750, "KNOCK_DOWN_FORCE": 1500, "CAN_JUMP": true }
]

func params_idx():
	var hp_ratio = hp_ratio()
	if hp_ratio > 80:
		return 0
	elif hp_ratio > 40:
		return 1
	return 2

func hp_ratio():
	return float(_hp) / float(MAX_HP) * 100.0

func walk_speed():
	return PARAMS[params_idx()].WALK_SPEED

func gravity():
	return PARAMS[params_idx()].GRAVITY

func jump_force():
	return PARAMS[params_idx()].JUMP_FORCE

func knock_down_force():
	return PARAMS[params_idx()].KNOCK_DOWN_FORCE

func can_jump():
	return PARAMS[params_idx()].CAN_JUMP

enum STATE {
	HIT,
	WALK,
	BEING_HIT,
	IDLE,
	JUMP,
	KO
}

var _current_left
var _hp
var _velocity
var _state
var _touch_floor
var _objective_cnt

func _ready():
	randomize()
	_objective_cnt = 0
	_attempt_jump = false
	_state = STATE.IDLE
	_node_anim.play("stand")
	_hp = MAX_HP
	_velocity = Vector2(0, 0)
	update_current_left()
	set_fixed_process(true)

var _hit_time_cnt = 0
const TIME_LIMIT = 1

var _objective_x
var _attempt_jump

func _fixed_process(delta):
	var pos = get_pos()
	if _state == STATE.IDLE:
		_velocity.x = 0
		update_current_left()
		_objective_x = find_objective()
		if is_near(pos.x, _objective_x) || _objective_cnt == 5:
			_objective_cnt = 0
			_hit_time_cnt += delta
			if _hit_time_cnt > TIME_LIMIT:
				_hit_time_cnt = 0
				_state = STATE.HIT
				_node_anim.play("hit_01")
		else:
			_state = STATE.WALK
			_node_anim.play("walk")
	elif _state == STATE.WALK:
		var new_left = null
		var is_near = is_near(pos.x, _objective_x)
		if is_near:
			_objective_cnt += 1
			print("ARRIVED " + str(_objective_cnt))
			_state = STATE.IDLE
			_node_anim.play("stand")
			_velocity.x = 0
		elif pos.x < _objective_x:
			new_left = -1
			_velocity.x = walk_speed()
		elif pos.x > _objective_x:
			new_left = 1
			_velocity.x = -walk_speed()
		if new_left != null && new_left != _current_left:
			set_scale(Vector2(new_left, 1))
			_current_left = new_left
		if !is_near && should_jump() && _attempt_jump && can_jump():
			_state = STATE.JUMP
			_velocity.y = -jump_force()
			_velocity.x = -walk_speed() * _current_left
			_touch_floor = false
	elif _state == STATE.JUMP:
		if _touch_floor:
			_state = STATE.IDLE
	apply_forces(delta)

func jump_fct(x):
	return Vector2(1 * cos(x + (PI/2.0)), 1 * sin(x - (PI/2.0)))

func is_near(pos_x, objective_x):
	return abs(pos_x - objective_x) < NEAR_THRESHOLD

func should_jump():
	var hero1 = get_tree().get_root().get_node("Main/hero1")
	var hero1_pos = hero1.get_pos()
	var pos = get_pos()
	var dist = abs(pos.x - hero1_pos.x)
	if (hero1_pos.x < pos.x && _current_left == 1 && dist < 400):
		return true
	if (hero1_pos.x > pos.x && _current_left == -1 && dist < 400):
		return true
	return false

func find_objective():
	var objective_x = 0
	var hero1 = get_tree().get_root().get_node("Main/hero1")
	var hero1_pos = hero1.get_pos()
	var pos = get_pos()
	if hero1_pos.x >= 0 && hero1_pos.x < 650:
		objective_x = 975
	elif hero1_pos.x >= 650 && hero1_pos.x < 1300:
		if pos.x > hero1_pos.x:
			objective_x = 1900
		else:
			objective_x = 50
	else:
		objective_x = 50
	return objective_x

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
	var force = Vector2(0, gravity())
	# Integrate forces to velocity
	_velocity += force * delta
	# Integrate velocity into motion and move
	var motion = _velocity * delta
	motion = move(motion)
	
	if (is_colliding()):
		var n = get_collision_normal()
		# touch the floor
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
			_touch_floor = 1
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
		_velocity = Vector2(_current_left * walk_speed() / 3, -knock_down_force())
		_node_defensive_hitbox_area.set_monitorable(false)
		_node_anim.play("ko")
		_state = STATE.KO
	elif !knock_down:
		_node_anim.play("being_hit")
		_state = STATE.BEING_HIT
	else:
		_node_defensive_hitbox_area.set_monitorable(false)
		_velocity = Vector2(_current_left * walk_speed(), -knock_down_force())
		_state = STATE.BEING_HIT
		get_node("anim").play("knock_down")

func recovered_hit():
	_node_anim.play("stand")
	_state = STATE.IDLE

func end_hit():
	_node_anim.play("stand")
	_state = STATE.IDLE

func get_up():
	var rand = randi()
	_attempt_jump = rand % 2 == 0
	print("rand: " + str(rand))
	print("ATTEMPT_JUMP: " + str(_attempt_jump))
	_node_defensive_hitbox_area.set_monitorable(true)
	_node_anim.play("stand")
	_state = STATE.IDLE

func dead():
	emit_signal("signal_dead", self)
	queue_free()