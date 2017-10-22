extends KinematicBody2D

signal state_changed

const MAX_LIFE = 3
const INIT_SPECIAL = 2
const MAX_HP = 20
const GRAVITY = 1000.0
const WALK_SPEED = 200
const SPECIAL_SPEED = 800
const JUMP_FORCE = 600

enum STATE {
	HIT,
	WALK,
	BEING_HIT,
	IDLE,
	KO,
	JUMP,
	FALL,
	JUMP_HIT,
	SPECIAL
}

var _hp
var _life
var _current_left
var _state
var _hit_released
var _jump_released
var _special_released
var _velocity
var _speed
var _special
var _special_cnt

onready var _node_anim = get_node("anim")
onready var _node_defensive_hitbox_area = get_node("defensive_hitbox_area")
onready var _node_offensive_hitbox_area = get_node("offensive_hitbox_area")
onready var _node_offensive_hitbox_area2 = get_node("offensive_hitbox_area2")
onready var _node_sound = get_node("sound")
onready var _node_timer = get_node("timer")

func _ready():
	set_fixed_process(true)
	_hp = MAX_HP
	_special = INIT_SPECIAL
	_life = MAX_LIFE
	_speed = WALK_SPEED
	_hit_released = true
	_current_left = -1
	_state = STATE.IDLE
	_velocity = Vector2(0, 0)
	set_scale(Vector2(_current_left, 1))
	_node_anim.play("stand")
	
func _fixed_process(delta):
	var action_hit = Input.is_action_pressed("hit")
	var action_special = Input.is_action_pressed("special")
	var walk_left = Input.is_action_pressed("ui_left")
	var walk_right = Input.is_action_pressed("ui_right")
	var action_jump = Input.is_action_pressed("jump")
	var new_left = null
	
	# disable offensive hitbox area in case animation got interrupted
	if (![STATE.HIT, STATE.SPECIAL].has(_state) && _node_offensive_hitbox_area.is_monitoring_enabled()):
		_node_offensive_hitbox_area.set_enable_monitoring(false)
	
	if (!action_hit):
		_hit_released = true
	if (!action_jump):
		_jump_released = true
	if !action_special:
		_special_released = true
	if (_special_released && action_special):
		_special_released = false
		if (![STATE.SPECIAL, STATE.KO].has(_state) && _special > 0):
			_special -= 1
			emit_signal("state_changed", self)
			_state = STATE.SPECIAL
			_speed = SPECIAL_SPEED
			_node_timer.start()
			_node_defensive_hitbox_area.set_monitorable(false)
			_node_anim.play("special")
	elif (_hit_released && action_hit):
		_hit_released = false
		if (_state == STATE.IDLE || _state == STATE.WALK):
			_node_anim.play("hit_01")
			_state = STATE.HIT
			_velocity.x = 0
	#elif (_jump_released && action_jump):
	#	_jump_released = false
	#	if (_state == STATE.IDLE || _state == STATE.WALK):
	#		jump()
	elif (walk_right):
		if (_state == STATE.SPECIAL || _state == STATE.IDLE || (_state == STATE.WALK && _current_left == 1)):
			new_left = -1
			_velocity.x = _speed
			if (_state != STATE.SPECIAL):
				_node_anim.play("walk")
				_state = STATE.WALK
	elif walk_left:
		if (_state == STATE.SPECIAL || _state == STATE.IDLE || (_state == STATE.WALK && _current_left == -1)):
			new_left = 1
			_velocity.x = -_speed
			if (_state != STATE.SPECIAL):
				_node_anim.play("walk")
				_state = STATE.WALK
	else:
		if (_state == STATE.WALK):
			_node_anim.play("stand")
			_state = STATE.IDLE
			_velocity.x = 0
		elif (_state == STATE.SPECIAL):
			_velocity.x = 0
	
	if (new_left != null && new_left != _current_left):
		set_scale(Vector2(new_left, 1))
		_current_left = new_left
	
	move_body(delta)

func move_body(delta):
	var force = Vector2(0, GRAVITY)
	
	# Integrate forces to velocity
	_velocity += force * delta
	# Integrate velocity into motion and move
	var motion = _velocity * delta
	motion = move(motion)
	
	# Not be blocked on border (slide instead)
	if is_colliding():
		var n = get_collision_normal()
		motion = n.slide(motion)
		_velocity = n.slide(_velocity)
		motion = move(motion)

func _on_offensive_hitbox_area_area_enter( area ):
	print("_on_offensive_hitbox_area_area_enter")
	var enemy = area.get_node("../")
	enemy.get_hit()
	_node_sound.play("punch_01")

func end_hit():
	_state = STATE.IDLE
	_node_anim.play("stand")
	
func get_hit():
	_velocity.x = 0
	_hp -= 1
	if (_hp == 0):
		_node_anim.play("ko")
		_state = STATE.KO
	else:
		_node_anim.play("being_hit")
		_state = STATE.BEING_HIT
	emit_signal("state_changed", self)

func recovered_hit():
	_node_anim.play("stand")
	_state = STATE.IDLE
	
func get_life():
	return _life

func get_hp():
	return _hp

func get_max_life():
	return MAX_LIFE

func get_max_hp():
	return MAX_HP
	
func dead():
	_life -= 1
	if _life == 0:
		#TODO: Game Over
		emit_signal("state_changed", self)
		get_node("../bgm").stop()
		get_node("../bgm_gameover").play()
		pass
	else:
		respawn()

func respawn():
	_hp = MAX_HP
	_state = STATE.IDLE
	_current_left = -1
	set_scale(Vector2(_current_left, 1))
	_node_anim.play("stand")
	get_node("defensive_hitbox_area").set_monitorable(true)
	set_pos(Vector2(get_pos().x, 0))
	emit_signal("state_changed", self)

func jump():
	_state = STATE.JUMP
	_velocity.y = -JUMP_FORCE
	_node_anim.play("jump")
	pass
	
func fall():
	_node_anim.play("fall")

func get_special():
	return _special

func _on_timer_timeout():
	_state = STATE.IDLE
	_node_anim.play("stand")
	_speed = WALK_SPEED
	_node_offensive_hitbox_area2.set_enable_monitoring(false)
	_node_defensive_hitbox_area.set_monitorable(true)
	pass
