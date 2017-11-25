extends KinematicBody2D

signal state_changed

const MAX_HP = 30
const GRAVITY = 1000.0
const WALK_SPEED = 200
const RUN_SPEED = 400
const SPECIAL_SPEED = 800
const JUMP_FORCE = 600
const INVINCIBILITY_TIME = 0.5
const RESPAWN_INVINCIBILITY_TIME = 2

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
	SPECIAL,
	SPECIAL_SETUP
}

export var _player = "p1"
export var _control = "keyboard"

var _attributes
#var _hp
#var _life
#var _special
var _current_left
var _state
var _hit_released
var _jump_released
var _run_released
var _special_released
var _velocity
var _speed
var _special_cnt
var _touch_floor
var _combo_count
var _last_hit_connect
var _combo_frame_count
var _power
var _knock_down
var _invicibility_cnt
var _pickables
var _freeze

var preload_spark = preload("res://scenes/spark_hit.tscn")

onready var _node_anim = get_node("anim")
onready var _node_defensive_hitbox_area = get_node("defensive_hitbox_areas/1")
onready var _node_offensive_hitbox_area = get_node("offensive_hitbox_areas/1")
onready var _node_offensive_hitbox_area2 = get_node("offensive_hitbox_areas/2")
onready var _node_offensive_hitbox_area3 = get_node("offensive_hitbox_areas/3")
onready var _node_sound = get_node("sound")
onready var _node_timer = get_node("timer")
onready var _node_camera = get_node("camera")

func _init():
	_attributes = globals.player_attributes[_player]

func _ready():
	set_fixed_process(true)
	_invicibility_cnt = 0
#	_hp = MAX_HP
#	_special = INIT_SPECIAL
#	_life = MAX_LIFE
	_freeze = false
	_speed = WALK_SPEED
	_hit_released = true
	_current_left = -1
	defensive_hitbox(true)
	_state = STATE.FALL
	_velocity = Vector2(0, 0)
	set_scale(Vector2(_current_left, 1))
	_node_anim.play("fall")
	_touch_floor = false
	_combo_count = 0
	_last_hit_connect = false
	_combo_frame_count = 0
	_pickables = {}

func _fixed_process(delta):
	if _freeze:
		return
	
	var action_hit = utils.is_input_action_pressed(_control, "hit")
	var action_special = utils.is_input_action_pressed(_control, "special")
	var walk_left = utils.is_input_action_pressed(_control, "left")
	var walk_right = utils.is_input_action_pressed(_control, "right")
	var action_jump = utils.is_input_action_pressed(_control, "jump")
	var action_run = utils.is_input_action_pressed(_control, "run")
	var new_left = null

	if _invicibility_cnt > 0:
		_invicibility_cnt -= delta
		if _invicibility_cnt < 0:
			if ![STATE.SPECIAL, STATE.SPECIAL_SETUP].has(_state):
				defensive_hitbox(true)
			_invicibility_cnt = 0

	# disable offensive hitbox area in case animation got interrupted
	if (![STATE.HIT].has(_state) && _node_offensive_hitbox_area.is_monitoring_enabled()):
		_node_offensive_hitbox_area.set_enable_monitoring(false)
	if (![STATE.JUMP_HIT].has(_state) && _node_offensive_hitbox_area3.is_monitoring_enabled()):
		_node_offensive_hitbox_area3.set_enable_monitoring(false)

	# Check if item can be consumed
	if ![STATE.KO, STATE.BEING_HIT].has(_state):
		check_items_to_consume()

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
		if (![STATE.SPECIAL, STATE.KO, STATE.SPECIAL_SETUP].has(_state) && _attributes.specials > 0):
			_attributes.specials -= 1
			emit_signal("state_changed", self)
			_state = STATE.SPECIAL_SETUP
			defensive_hitbox(false)
			_node_sound.play("special_charge")
			_node_anim.play("special_setup")
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
			_state = STATE.RUN
		if (_state == STATE.RUN && !action_run):
			_speed = WALK_SPEED
			new_left = -1
			_velocity.x = _speed
			_node_anim.play("walk")
			_state = STATE.WALK
		if ([STATE.JUMP, STATE.SPECIAL, STATE.IDLE, STATE.FALL].has(_state) || ([STATE.WALK, STATE.RUN].has(_state) && _current_left == 1)):
			new_left = -1
			_velocity.x = _speed
			if (![STATE.JUMP, STATE.FALL, STATE.SPECIAL].has(_state)):
				_speed = WALK_SPEED
				_velocity.x = _speed
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
			_node_anim.play("walk")
			_state = STATE.WALK
		if ([STATE.JUMP, STATE.SPECIAL, STATE.IDLE, STATE.FALL].has(_state) || (_state == STATE.WALK && _current_left == -1)):
			new_left = 1
			_velocity.x = -_speed
			if (![STATE.JUMP, STATE.FALL, STATE.SPECIAL].has(_state)):
				_speed = WALK_SPEED
				_velocity.x = _speed
				_node_anim.play("walk")
				_state = STATE.WALK
		if [STATE.WALK, STATE.RUN, STATE.SPECIAL].has(_state):
			_velocity.x = -_speed
	else:
		if ([STATE.WALK, STATE.RUN].has(_state)):
			_node_anim.play("stand")
			_state = STATE.IDLE
			_speed = WALK_SPEED
			_velocity.x = 0
		elif [STATE.SPECIAL].has(_state):
			_velocity.x = 0
		if _state == STATE.IDLE || _state == STATE.HIT || _state == STATE.BEING_HIT:
			_velocity.x = 0
	
	#print("Is colliding: " + str(is_colliding()))
	#print("Collision normal: " + str(get_collision_normal()))
	
	if (new_left != null && new_left != _current_left):
		set_scale(Vector2(new_left, 1))
		_current_left = new_left
	
	if _state != STATE.SPECIAL_SETUP:
		move_body(delta)

func check_items_to_consume():
	if _pickables.size() > 0:
		for key in _pickables.keys():
			var wkRef = _pickables[key]
			if wkRef.get_ref() != null:
				wkRef.get_ref().consume(self)
				remove_pickable(key)
				break

func restore_hp(hp):
	print("RESTORE %d HP" % hp)
	_node_sound.play("eat")
	_attributes.hp += hp
	if (_attributes.hp > MAX_HP):
		_attributes.hp = MAX_HP
	emit_signal("state_changed", self)

func add_life(lives):
	_attributes.lives += lives
	_node_sound.play("eat")
	emit_signal("state_changed", self)

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
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < globals.FLOOR_ANGLE_TOLERANCE):
			new_touch_floor = true
			if (_state == STATE.JUMP_HIT):
				_node_offensive_hitbox_area3.set_enable_monitoring(false)
			if ([STATE.JUMP, STATE.FALL, STATE.JUMP_HIT].has(_state)):
				_state = STATE.IDLE
				_node_anim.play("stand")
				_velocity.x = 0
				_speed = WALK_SPEED
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
	enemy.get_hit(self, _power, _knock_down)
	_last_hit_connect = true
	var spark
	if _knock_down:
		spark = preload_spark.instance()
		_node_sound.play("punch_02")
	else:
		spark = preload_spark.instance()
		_node_sound.play("punch_01")
	var pos = Vector2()
	pos.x = (area.get_global_pos().x + _node_offensive_hitbox_area.get_global_pos().x) / 2
	pos.y = (area.get_global_pos().y + _node_offensive_hitbox_area.get_global_pos().y) / 2
	spark.set_pos(pos)
	spark.set_scale(Vector2(_current_left, 1))
	get_node("../../").add_child(spark)

func end_hit():
	_state = STATE.IDLE
	_node_anim.play("stand")
	
func get_hit(hitter, power, knock_down):
	_speed = WALK_SPEED
	_velocity.x = 0
	#print(str(_attributes.hp) + " - " + str(power))
	_attributes.hp -= power
	if _attributes.hp <= 0:
		_node_camera.shake(globals.DEFAULT_SHAKE_MAGNITUDE, globals.DEFAULT_SHAKE_DURATION)
		defensive_hitbox(false)
		_velocity = Vector2(_current_left * _speed, -200)
		_node_anim.play("ko")
		_state = STATE.KO
	elif !knock_down:
		_node_anim.play("being_hit")
		_state = STATE.BEING_HIT
	else:
		_node_camera.shake(globals.DEFAULT_SHAKE_MAGNITUDE, globals.DEFAULT_SHAKE_DURATION)
		defensive_hitbox(false)
		_velocity = Vector2(_current_left * _speed, -200)
		_node_anim.play("knock_down")
		_state = STATE.BEING_HIT
	emit_signal("state_changed", self)

func recovered_hit():
	defensive_hitbox(true)
	if _touch_floor:
		_node_anim.play("stand")
		_state = STATE.IDLE
	else:
		_node_anim.play("fall")
		_state = STATE.FALL

func get_up():
	_invicibility_cnt = INVINCIBILITY_TIME
	_node_anim.play("stand")
	_state = STATE.IDLE

func get_lives():
	return _attributes.lives

func get_hp():
	return _attributes.hp

func get_max_hp():
	return MAX_HP
	
func dead():
	_attributes.lives -= 1
	if _attributes.lives == 0:
		#TODO: Game Over
		emit_signal("state_changed", self)
		bgms.play("game_over")
	else:
		respawn()

func respawn():
	_attributes.hp = MAX_HP
	_attributes.specials = globals.INIT_SPECIALS
	_state = STATE.FALL
	_node_anim.play("fall")
	_touch_floor = false
	_current_left = -1
	_velocity = Vector2(0, 0)
	set_scale(Vector2(_current_left, 1))
	defensive_hitbox(false)
	_invicibility_cnt = RESPAWN_INVINCIBILITY_TIME
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

func get_specials():
	return _attributes.specials

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

func defensive_hitbox(active):
	_node_defensive_hitbox_area.set_monitorable(active)

func get_player():
	return _player

func get_score():
	return _attributes.score

func add_score(value):
	_attributes.score += value
	emit_signal("state_changed", self)

func set_player(player):
	_player = player
	_attributes = globals.player_attributes[_player]

func set_control(control):
	_control = control

func get_current_left():
	return _current_left

func add_pickable(pickable):
	print(pickable)
	_pickables[pickable.get_instance_ID()] = weakref(pickable)

func remove_pickable(id):
	_pickables.erase(id)

func special_setup_finished():
	_power = 3
	_knock_down = true
	_speed = SPECIAL_SPEED
	_node_timer.start()
	_state = STATE.SPECIAL
	_node_anim.play("special")

func add_special(nb_specials):
	_attributes.specials += nb_specials
	_node_sound.play("special_charge")
	emit_signal("state_changed", self)

func set_hp(hp):
	_attributes.hp = hp

func set_freeze(freeze):
	_freeze = freeze

func set_specials(specials):
	_attributes.specials = specials