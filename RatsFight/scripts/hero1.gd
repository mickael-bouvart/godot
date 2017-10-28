extends KinematicBody2D

signal state_changed

# Angle in degrees towards either side that the player can consider "floor"
const FLOOR_ANGLE_TOLERANCE = 40
const MAX_LIFE = 3
const INIT_SPECIAL = 2
const MAX_HP = 20
const GRAVITY = 1000.0
const WALK_SPEED = 200
const RUN_SPEED = 400
const SPECIAL_SPEED = 800
const JUMP_FORCE = 600

enum STATE {
	HIT,
	WALK,
	RUN,
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
var _run_released
var _special_released
var _velocity
var _speed
var _special
var _special_cnt
var _touch_floor
var _combo_count
var _last_hit_connect
var _combo_frame_count
var _power
var _knock_down

onready var _node_anim = get_node("anim")
onready var _node_defensive_hitbox_area = get_node("defensive_hitbox_area")
onready var _node_offensive_hitbox_area = get_node("offensive_hitbox_area")
onready var _node_offensive_hitbox_area2 = get_node("offensive_hitbox_area2")
onready var _node_offensive_hitbox_area3 = get_node("offensive_hitbox_area3")
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
	defensive_hitbox(true)
	_state = STATE.IDLE
	_velocity = Vector2(0, 0)
	set_scale(Vector2(_current_left, 1))
	_node_anim.play("stand")
	_touch_floor = false
	_combo_count = 0
	_last_hit_connect = false
	_combo_frame_count = 0
	
func _fixed_process(delta):
	var action_hit = Input.is_action_pressed("hit")
	var action_special = Input.is_action_pressed("special")
	var walk_left = Input.is_action_pressed("ui_left")
	var walk_right = Input.is_action_pressed("ui_right")
	var action_jump = Input.is_action_pressed("jump")
	var action_run = Input.is_action_pressed("run")
	var new_left = null
	
	# disable offensive hitbox area in case animation got interrupted
	if (![STATE.HIT].has(_state) && _node_offensive_hitbox_area.is_monitoring_enabled()):
		_node_offensive_hitbox_area.set_enable_monitoring(false)
	if (![STATE.JUMP_HIT].has(_state) && _node_offensive_hitbox_area3.is_monitoring_enabled()):
		_node_offensive_hitbox_area3.set_enable_monitoring(false)
	
	_combo_frame_count += 1
	if (!action_hit):
		_hit_released = true
	if (!action_jump):
		_jump_released = true
	if (!action_run):
		_run_released = true
	if !action_special:
		_special_released = true
	if (_special_released && action_special):
		_special_released = false
		if (![STATE.SPECIAL, STATE.KO].has(_state) && _special > 0):
			_special -= 1
			emit_signal("state_changed", self)
			_power = 3
			_knock_down = true
			_state = STATE.SPECIAL
			_speed = SPECIAL_SPEED
			_node_timer.start()
			defensive_hitbox(false)
			_node_anim.play("special")
	if (_hit_released && action_hit):
		_hit_released = false
		if (_state == STATE.IDLE || _state == STATE.WALK):
			_state = STATE.HIT
			if _last_hit_connect:
				_combo_count += 1
				_last_hit_connect = false
			else:
				_combo_count = 0
			if _combo_frame_count > 100:
				_combo_count = 0
			_combo_frame_count = 0
			if _combo_count == 2:
				_power = 2
				_knock_down = true
				_node_anim.play("hit_02")
				_combo_count = -1
			else:
				_power = 1
				_knock_down = false
				_node_anim.play("hit_01")
			_velocity.x = 0
		elif ([STATE.JUMP, STATE.FALL].has(_state)):
			_velocity.x += 150 * -_current_left
			_velocity.y += 50
			_power = 1
			_knock_down = false
			_node_anim.play("jump_hit")
			_state = STATE.JUMP_HIT
	if (_jump_released && action_jump):
		_jump_released = false
		if ([STATE.IDLE, STATE.WALK, STATE.RUN, STATE.SPECIAL].has(_state) && _touch_floor):
			jump()
	if (walk_right):
		if (action_run && (_state == STATE.WALK || (_state == STATE.RUN && _current_left == 1))):
			new_left = -1
			_speed = RUN_SPEED
			_velocity.x = _speed
			_node_anim.play("run")
			defensive_hitbox(true)
			_state = STATE.RUN
		if (_state == STATE.RUN && !action_run):
			_speed = WALK_SPEED
			new_left = -1
			_velocity.x = _speed
			_node_anim.play("walk")
			defensive_hitbox(true)
			_state = STATE.WALK
		if ([STATE.JUMP, STATE.SPECIAL, STATE.IDLE, STATE.FALL].has(_state) || ([STATE.WALK, STATE.RUN].has(_state) && _current_left == 1)):
			new_left = -1
			_velocity.x = _speed
			if (![STATE.JUMP, STATE.FALL, STATE.SPECIAL].has(_state)):
				defensive_hitbox(true)
				_node_anim.play("walk")
				_state = STATE.WALK
		if [STATE.WALK, STATE.RUN, STATE.SPECIAL].has(_state):
			_velocity.x = _speed
	elif walk_left:
		if (action_run && (_state == STATE.WALK || (_state == STATE.RUN && _current_left == -1))):
			new_left = 1
			_speed = RUN_SPEED
			_velocity.x = -_speed
			_node_anim.play("run")
			_state = STATE.RUN
		if (_state == STATE.RUN && !action_run):
			_speed = WALK_SPEED
			new_left = 1
			_velocity.x = -_speed
			defensive_hitbox(true)
			_node_anim.play("walk")
			_state = STATE.WALK
		if ([STATE.JUMP, STATE.SPECIAL, STATE.IDLE, STATE.FALL].has(_state) || (_state == STATE.WALK && _current_left == -1)):
			new_left = 1
			_velocity.x = -_speed
			if (![STATE.JUMP, STATE.FALL, STATE.SPECIAL].has(_state)):
				defensive_hitbox(true)
				_node_anim.play("walk")
				_state = STATE.WALK
		if [STATE.WALK, STATE.RUN, STATE.SPECIAL].has(_state):
			_velocity.x = -_speed
	else:
		if ([STATE.WALK, STATE.RUN].has(_state)):
			defensive_hitbox(true)
			_node_anim.play("stand")
			_state = STATE.IDLE
			_speed = WALK_SPEED
			_velocity.x = 0
		elif (_state == STATE.SPECIAL):
			_velocity.x = 0
		if _state == STATE.IDLE || _state == STATE.HIT || _state == STATE.BEING_HIT:
			_velocity.x = 0
	
	#print("Is colliding: " + str(is_colliding()))
	#print("Collision normal: " + str(get_collision_normal()))
	
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
	var new_touch_floor = null
	if is_colliding():
		#print(get_collider())
		var n = get_collision_normal()
		#print(n)
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
			new_touch_floor = true
			if ([STATE.JUMP, STATE.FALL, STATE.JUMP_HIT].has(_state)):
				defensive_hitbox(true)
				_state = STATE.IDLE
				_node_anim.play("stand")
				_velocity.x = 0
				_speed = WALK_SPEED
			if (_state == STATE.JUMP_HIT):
				_node_offensive_hitbox_area3.set_enable_monitoring(false)
		if (![STATE.BEING_HIT, STATE.KO].has(_state) || !new_touch_floor):
			motion = n.slide(motion)
			_velocity = n.slide(_velocity)
		motion = move(motion)
	else:
		if _velocity.y > 0 && _state == STATE.JUMP:
			_state = STATE.FALL
			_node_anim.play("fall")
	if new_touch_floor != null:
		_touch_floor = new_touch_floor

func _on_offensive_hitbox_area_area_enter( area ):
	#print("_on_offensive_hitbox_area_area_enter")
	var enemy = area.get_node("../")
	enemy.get_hit(_power, _knock_down)
	_last_hit_connect = true
	_node_sound.play("punch_01")

func end_hit():
	defensive_hitbox(true)
	_state = STATE.IDLE
	_node_anim.play("stand")
	
func get_hit(power, knock_down):
	_speed = WALK_SPEED
	_velocity.x = 0
	_hp -= power
	if _hp <= 0:
		_velocity = Vector2(_current_left * _speed, -200)
		_node_anim.play("ko")
		_state = STATE.KO
	elif !knock_down:
		_node_anim.play("being_hit")
		_state = STATE.BEING_HIT
	else:
		_velocity = Vector2(_current_left * _speed, -200)
		_node_anim.play("knock_down")
		_state = STATE.BEING_HIT
	emit_signal("state_changed", self)

func recovered_hit():
	if _touch_floor:
		defensive_hitbox(true)
		_node_anim.play("stand")
		_state = STATE.IDLE
	else:
		_node_anim.play("fall")
		_state = STATE.FALL

func get_up():
	print("GET_UP")
	print(str(_node_defensive_hitbox_area.is_monitorable()))
	defensive_hitbox(true)
	print(str(_node_defensive_hitbox_area.is_monitorable()))
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
		bgms.play("game_over")
		pass
	else:
		respawn()

func respawn():
	_hp = MAX_HP
	_special = INIT_SPECIAL
	_state = STATE.FALL
	_node_anim.play("fall")
	_touch_floor = false
	_current_left = -1
	_velocity = Vector2(0, 0)
	set_scale(Vector2(_current_left, 1))
	get_node("defensive_hitbox_area").set_monitorable(true)
	set_pos(Vector2(get_pos().x, 0))
	emit_signal("state_changed", self)

func jump():
	if _state != STATE.SPECIAL:
		_state = STATE.JUMP
		_node_anim.play("jump")
	_velocity.y = -JUMP_FORCE
	_touch_floor = false
	
func fall():
	_node_anim.play("fall")

func get_special():
	return _special

func last_hit_connected():
	_last_hit_connect = true

func _on_timer_timeout():
	if _touch_floor:
		_state = STATE.IDLE
		_node_anim.play("stand")
	else:
		_state = STATE.FALL
		_node_anim.play("fall")
	_speed = WALK_SPEED
	_node_offensive_hitbox_area2.set_enable_monitoring(false)
	defensive_hitbox(true)
	pass

func defensive_hitbox(active):
	_node_defensive_hitbox_area.set_monitorable(active)