# Hero2: Squirrel
# List of States:
#	StandState
#	WalkState
#	RunState
#	HitState
#	JumpState
#	FallState
#	JumpHitState
#	GlideState
#	SpecialSetupState
#	SpecialStepOneState
#	SpecialStepTwoState
#	SpecialStepThreeState
#	BeingHitState
#	KnockedUpState
#	KnockedDownState
#	KOState
#	FreezeState

extends KinematicBody2D

signal state_changed

const MAX_HP = 20
const GRAVITY = 1000.0
const WALK_SPEED = 250
const RUN_SPEED = 600
const SPECIAL_SPEED = 800
const JUMP_FORCE = 600
const INVINCIBILITY_TIME = 0.5
const RESPAWN_INVINCIBILITY_TIME = 2

export var _player = "p1"
export var _control = "keyboard"

var _attributes
var _states
var _state
var _current_left
var _new_left
var _velocity
var _speed
var _pickables
var _hitting
var _jump_cnt
var _touch_floor
var _hits_received
var _recovered_hit
var _got_up
var _power
var _knock_down
var _combo_count
var _last_hit_connect
var _combo_expired
var _special_setup
var _invincibility_cnt
var _freeze_old_state
var _can_run

var _input_walk_right
var _input_walk_right_prev
var _input_walk_left
var _input_walk_left_prev
var _input_jump_prev
var _input_jump
var _input_hit_prev
var _input_hit
var _input_special_prev
var _input_special

var preload_spark = preload("res://scenes/spark_hit.tscn")

onready var _node_sprite = get_node("sprite")
onready var _node_anim = get_node("anim")
onready var _node_anim_invincible = get_node("anim_invincible")
onready var _node_defensive_hitbox_area = get_node("defensive_hitbox_areas/1")
onready var _node_offensive_hitbox_area1 = get_node("offensive_hitbox_areas/1")
onready var _node_offensive_hitbox_area2 = get_node("offensive_hitbox_areas/2")
onready var _node_offensive_hitbox_area3 = get_node("offensive_hitbox_areas/3")
onready var _node_offensive_hitbox_area4 = get_node("offensive_hitbox_areas/4")
onready var _node_sound = get_node("sound")
onready var _node_timer_combo = get_node("timers/timer_combo")
onready var _node_timer_run = get_node("timers/timer_run")
onready var _node_camera = get_node("camera")
onready var _node_particles = get_node("particles")

func change_state(new_state):
	if _state != null:
		_states[_state].end()
	_state = new_state
	_states[_state].start()

func check_hits_received():
	if _hits_received.size() == 0:
		return null
	var next_hit = _hits_received.front()
	var hitter = next_hit[0]
	var power = next_hit[1]
	var knock_down = next_hit[2]
	if power > _attributes.hp || knock_down > 0:
		return globals.STATE.KNOCKED_UP
	else:
		return globals.STATE.BEING_HIT

class FreezeState:
	func start():
		pass
	func update(delta):
		pass
	func end():
		pass

class KnockedUpState:
	var _parent
	
	func _init(parent):
		_parent = parent

	func start():
		var next_hit = _parent._hits_received.front()
		_parent._hits_received.pop_front()
		_parent.lose_hp(next_hit[1])
		_parent.signal_state_changed()
		_parent.defensive_hitbox(false)
		_parent._touch_floor = false
		_parent._velocity = Vector2(_parent._current_left * 500, -400)
		_parent._node_anim.play("knock_up")
	
	func update(delta):
		_parent.move_body(delta)
		# Switch to KNOCKED_DOWN or KO
		if _parent._touch_floor:
			if _parent._attributes.hp > 0:
				_parent.change_state(globals.STATE.KNOCKED_DOWN)
			else:
				_parent.change_state(globals.STATE.KO)
	func end():
		pass

class KnockedDownState:
	var _parent
	
	func _init(parent):
		_parent = parent

	func start():
		_parent._got_up = false
		_parent._node_anim.play("knock_down")
	
	func update(delta):
		_parent._velocity.x = 0
		_parent.move_body(delta)
		# Switch to IDLE
		if _parent._got_up:
			_parent.change_state(globals.STATE.IDLE)
	
	func end():
		_parent._invincibility_cnt = INVINCIBILITY_TIME
		_parent._node_anim_invincible.play("invincible")
		#_parent._node_defensive_hitbox_area.set_monitorable(true)

class KOState:
	var _parent
	
	func _init(parent):
		_parent = parent

	func start():
		_parent._node_anim.play("ko")
	
	func update(delta):
		_parent._velocity.x = 0
	
	func end():
		_parent._node_defensive_hitbox_area.set_monitorable(true)

class BeingHitState:
	var _parent
	
	func _init(parent):
		_parent = parent

	func start():
		var next_hit = _parent._hits_received.front()
		_parent._hits_received.pop_front()
		_parent.lose_hp(next_hit[1])
		_parent.signal_state_changed()
		_parent._recovered_hit = false
		_parent._node_anim.play("being_hit")
		_parent._velocity.x = 0

	func update(delta):
		_parent.move_body(delta)
		# Switch to BEING_HIT again (ouch...)
		var get_hit_state = _parent.check_hits_received()
		if get_hit_state != null:
			_parent.change_state(get_hit_state)
		# Switch to IDLE or FALL
		elif _parent._recovered_hit:
			if _parent._touch_floor:
				_parent.change_state(globals.STATE.IDLE)
			else:
				_parent.change_state(globals.STATE.FALL)
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)

	func end():
		pass

class StandState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._speed = WALK_SPEED
		_parent._node_anim.play("stand")

	func update(delta):
		_parent.check_invincible(delta)
		_parent._velocity.x = 0
		_parent.move_body(delta)
		_parent.check_items_to_consume()
		
		# Switch to BEING_HIT
		var get_hit_state = _parent.check_hits_received()
		if get_hit_state != null:
			_parent.change_state(get_hit_state)
		# Switch to WALK or RUN
		elif _parent._input_walk_right || _parent._input_walk_left:
			_parent._new_left = -1 if _parent._input_walk_right else 1
			if (_parent._can_run >= 2 && _parent._new_left == _parent._current_left):# || _parent._input_run:
				_parent.change_state(globals.STATE.RUN)
			else:
				_parent.change_state(globals.STATE.WALK)
		# Switch to JUMP
		elif _parent.input_jump_just_pressed():
			_parent._jump_cnt = 1
			_parent.change_state(globals.STATE.JUMP)
		# Switch to HIT
		elif _parent.input_hit_just_pressed():
			_parent.change_state(globals.STATE.HIT)
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)
			
	func end():
		pass

class WalkState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._speed = WALK_SPEED
		_parent._node_anim.play("walk")
		if _parent._new_left != _parent._current_left:
			_parent._current_left = _parent._new_left
			_parent.set_scale(Vector2(_parent._current_left, 1))

	func update(delta):
		_parent.check_invincible(delta)
		_parent._velocity.x = -_parent._speed * _parent._current_left
		_parent.move_body(delta)
		_parent.check_items_to_consume()
		# Switch to BEING_HIT
		var get_hit_state = _parent.check_hits_received()
		if get_hit_state != null:
			_parent.change_state(get_hit_state)
		# Switch to IDLE
		elif	(_parent._current_left == -1 && !_parent._input_walk_right)	\
			||	(_parent._current_left == 1 && !_parent._input_walk_left):
			_parent.change_state(globals.STATE.IDLE)
		# Switch to JUMP
		elif _parent.input_jump_just_pressed():
			_parent._jump_cnt = 1
			_parent.change_state(globals.STATE.JUMP)
		# Switch to HIT
		elif _parent.input_hit_just_pressed():
			_parent.change_state(globals.STATE.HIT)
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)

	func end():
		pass

class RunState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._speed = RUN_SPEED
		_parent._node_anim.play("run")
		if _parent._new_left != _parent._current_left:
			_parent._current_left = _parent._new_left
			_parent.set_scale(Vector2(_parent._current_left, 1))

	func update(delta):
		_parent.check_invincible(delta)
		_parent._velocity.x = -_parent._speed * _parent._current_left
		_parent.move_body(delta)
		_parent.check_items_to_consume()
		# Switch to BEING_HIT
		var get_hit_state = _parent.check_hits_received()
		if get_hit_state != null:
			_parent.change_state(get_hit_state)
		# Switch to IDLE
		elif	(_parent._current_left == -1 && !_parent._input_walk_right)	\
			||	(_parent._current_left == 1 && !_parent._input_walk_left):
			_parent.change_state(globals.STATE.IDLE)
		# Switch to JUMP
		elif _parent.input_jump_just_pressed():
			_parent._jump_cnt = 1
			_parent.change_state(globals.STATE.JUMP)
		# Switch to HIT
		elif _parent.input_hit_just_pressed():
			_parent.change_state(globals.STATE.HIT)
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)

	func end():
		pass

class HitState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		if _parent._combo_expired:
			_parent._last_hit_connect = false
		if _parent._combo_count == 2:
			_parent._last_hit_connect = false
		if _parent._last_hit_connect:
			_parent._combo_count += 1
			_parent._last_hit_connect = false
		else:
			_parent._combo_count = 0
		
		_parent._velocity.x = 0
		_parent._hitting = true
		
		if _parent._combo_count == 2:
			_parent._node_anim.play("hit_02")
			_parent._power = 2
			_parent._knock_down = 1
		else:
			_parent._node_timer_combo.stop()
			_parent._combo_expired = false
			_parent._node_timer_combo.start()
			_parent._node_anim.play("hit_01")
			_parent._power = 1
			_parent._knock_down = 0

	func update(delta):
		_parent.check_invincible(delta)
		_parent.move_body(delta)
		# Switch to BEING_HIT
		var get_hit_state = _parent.check_hits_received()
		if get_hit_state != null:
			_parent.change_state(get_hit_state)
		# Switch to IDLE
		elif !_parent._hitting:
			_parent.change_state(globals.STATE.IDLE)
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)

	func end():
		_parent._node_offensive_hitbox_area1.set_enable_monitoring(false)
		_parent._node_offensive_hitbox_area2.set_enable_monitoring(false)

class JumpState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._node_anim.play("jump")
		_parent._velocity.y = -JUMP_FORCE
		_parent._touch_floor = false

	func update(delta):
		_parent.check_invincible(delta)
		# Moving left and right mid-air
		if (_parent._current_left == 1 && _parent._input_walk_right && !_parent._input_walk_left) \
			|| (_parent._current_left == -1 && _parent._input_walk_left && !_parent._input_walk_right):
			_parent._current_left *= -1
			_parent._velocity.x *= -1
			_parent.set_scale(Vector2(_parent._current_left, 1))
		if (_parent._input_walk_right || _parent._input_walk_left) && _parent._velocity.x == 0:
				_parent._velocity.x = -_parent._speed * _parent._current_left
		_parent.move_body(delta)
		_parent.check_items_to_consume()
		# Switch to BEING_HIT
		var get_hit_state = _parent.check_hits_received()
		if get_hit_state != null:
			_parent.change_state(get_hit_state)
		elif _parent.input_jump_just_pressed():
			if _parent._jump_cnt == 1:
				# Switch to JUMP (double jump)
				_parent.change_state(globals.STATE.JUMP)
			elif _parent._jump_cnt == 2:
				# Switch to GLIDE
				_parent.change_state(globals.STATE.GLIDE)
			_parent._jump_cnt += 1
		# Switch to JUMP_HIT
		elif _parent.input_hit_just_pressed():
			_parent.change_state(globals.STATE.JUMP_HIT)
		# Switch to FALL
		elif _parent._velocity.y > 0:
			_parent.change_state(globals.STATE.FALL)
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)

	func end():
		pass

class GlideState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._node_anim.play("glide")

	func update(delta):
		_parent.check_invincible(delta)
		_parent._velocity.y = 50
		_parent.move_body(delta)
		_parent.check_items_to_consume()
		# Switch to BEING_HIT
		var get_hit_state = _parent.check_hits_received()
		if get_hit_state != null:
			_parent.change_state(get_hit_state)
		# Switch to IDLE when touching floor
		elif _parent._touch_floor:
			_parent.change_state(globals.STATE.IDLE)
		# Switch to FALL
		elif !_parent._input_jump:
			_parent.change_state(globals.STATE.FALL)
		# Switch to JUMP_HIT
		elif _parent.input_hit_just_pressed():
			_parent.change_state(globals.STATE.JUMP_HIT)
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)

	func end():
		pass


class FallState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._node_anim.play("fall")

	func update(delta):
		_parent.check_invincible(delta)
		# Moving left and right mid-air
		if (_parent._current_left == 1 && _parent._input_walk_right && !_parent._input_walk_left) \
			|| (_parent._current_left == -1 && _parent._input_walk_left && !_parent._input_walk_right):
			_parent._current_left *= -1
			_parent._velocity.x *= -1
			_parent.set_scale(Vector2(_parent._current_left, 1))
		if (_parent._input_walk_right || _parent._input_walk_left) && _parent._velocity.x == 0:
				_parent._velocity.x = -_parent._speed * _parent._current_left
		_parent.move_body(delta)
		_parent.check_items_to_consume()
		# Switch to IDLE
		if _parent._touch_floor:
			_parent.change_state(globals.STATE.IDLE)
		elif _parent.input_jump_just_pressed():
			if _parent._jump_cnt == 1:
				# Switch to JUMP (double jump)
				_parent.change_state(globals.STATE.JUMP)
			elif _parent._jump_cnt == 2:
				# Switch to GLIDE
				_parent.change_state(globals.STATE.GLIDE)
			_parent._jump_cnt += 1
		# Switch to JUMP_HIT
		elif _parent.input_hit_just_pressed():
			_parent.change_state(globals.STATE.JUMP_HIT)
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)

	func end():
		pass

class JumpHitState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._power = 1
		_parent._knock_down = 0
		_parent._node_offensive_hitbox_area3.set_enable_monitoring(true)
		_parent._node_anim.play("jump_hit")

	func update(delta):
		_parent.check_invincible(delta)
		_parent.move_body(delta)
		_parent.check_items_to_consume()
		# Switch to BEING_HIT
		var get_hit_state = _parent.check_hits_received()
		if get_hit_state != null:
			_parent.change_state(get_hit_state)
		# Switch to IDLE
		elif _parent._touch_floor:
			_parent.change_state(globals.STATE.IDLE)
		elif _parent.input_jump_just_pressed():
			if _parent._jump_cnt == 1:
				# Switch to JUMP (double jump)
				_parent.change_state(globals.STATE.JUMP)
			elif _parent._jump_cnt == 2:
				# Switch to GLIDE
				_parent.change_state(globals.STATE.GLIDE)
			_parent._jump_cnt += 1
		# Switch to SPECIAL (SPECIAL_SETUP)
		elif _parent.input_special_just_pressed() && _parent.can_special():
			_parent.change_state(globals.STATE.SPECIAL_SETUP)

	func end():
		_parent._node_offensive_hitbox_area3.set_enable_monitoring(false)

class SpecialStepOneState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		# Disable invincibility to avoid conflict
		_parent.check_invincible(9999)
		_parent._attributes.specials -= 1
		_parent.signal_state_changed()
		_parent._special_setup = false
		_parent.defensive_hitbox(false)
		_parent._node_sound.play("special_charge")
		_parent._node_anim.play("special_setup")

	func update(delta):
		if _parent._special_setup:
			_parent.change_state(globals.STATE.SPECIAL_STEP_TWO)

	func end():
		pass

class SpecialSetupState:
	var _parent
	var _target_y

	func _init(parent):
		_parent = parent

	func start():
		_parent._node_particles.set_emitting(true)
		_parent._touch_floor = false
		_parent._node_anim.play("special_step_1")
		_target_y = _parent.get_pos().y - 225

	func update(delta):
		_parent._velocity.y = -1500
		_parent.move_body(delta)
		if _parent.get_pos().y < _target_y:
			_parent.change_state(globals.STATE.SPECIAL_STEP_ONE)

	func end():
		pass

class SpecialStepTwoState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._node_anim.play("special_step_2")
		_parent._velocity.y = 1500

	func update(delta):
		_parent.move_body(delta)
		if _parent._touch_floor:
			_parent.change_state(globals.STATE.SPECIAL_STEP_THREE)

	func end():
		pass

class SpecialStepThreeState:
	var _parent

	func _init(parent):
		_parent = parent

	func start():
		_parent._node_particles.set_emitting(false)
		_parent._power = 6
		_parent._knock_down = 9
		_parent._hitting = true
		_parent._node_sound.play("explosion")
		_parent._node_anim.play("special_step_3")

	func update(delta):
		if !_parent._hitting:
			_parent.change_state(globals.STATE.IDLE)

	func end():
		_parent._node_offensive_hitbox_area4.set_enable_monitoring(false)
		_parent.defensive_hitbox(true)

func _init():
	_attributes = globals.player_attributes[_player]
	_states = {
		globals.STATE.FREEZE: FreezeState.new(),
		globals.STATE.IDLE: StandState.new(self),
		globals.STATE.WALK: WalkState.new(self),
		globals.STATE.RUN: RunState.new(self),
		globals.STATE.HIT: HitState.new(self),
		globals.STATE.JUMP: JumpState.new(self),
		globals.STATE.FALL: FallState.new(self),
		globals.STATE.JUMP_HIT: JumpHitState.new(self),
		globals.STATE.GLIDE: GlideState.new(self),
		globals.STATE.BEING_HIT: BeingHitState.new(self),
		globals.STATE.KNOCKED_UP: KnockedUpState.new(self),
		globals.STATE.KNOCKED_DOWN: KnockedDownState.new(self),
		globals.STATE.KO: KOState.new(self),
		globals.STATE.SPECIAL_SETUP: SpecialSetupState.new(self),
		globals.STATE.SPECIAL_STEP_ONE: SpecialStepOneState.new(self),
		globals.STATE.SPECIAL_STEP_TWO: SpecialStepTwoState.new(self),
		globals.STATE.SPECIAL_STEP_THREE: SpecialStepThreeState.new(self)
	}

func _ready():
	set_fixed_process(true)
	_invincibility_cnt = 0
#	_hp = MAX_HP
#	_special = INIT_SPECIAL
#	_life = MAX_LIFE
	_freeze_old_state = null
	_speed = WALK_SPEED
	_current_left = -1
	_can_run = false
	defensive_hitbox(true)
	_velocity = Vector2(0, 0)
	set_scale(Vector2(_current_left, 1))
	_node_anim.play("fall")
	_touch_floor = false
	_combo_count = 0
	_combo_expired = true
	_last_hit_connect = false
	_pickables = {}
	_hits_received = []
	_state = globals.STATE.FALL
	_states[_state].start()
	_jump_cnt = 9999
	reset_offensive_hitboxes()

func _fixed_process(delta):
	check_inputs()
	_states[_state].update(delta)

func check_inputs():
	_input_jump_prev = _input_jump
	_input_hit_prev = _input_hit
	_input_special_prev = _input_special
	_input_walk_left_prev = _input_walk_left
	_input_walk_right_prev = _input_walk_right
	_input_walk_left = utils.is_input_action_pressed(_control, "left")
	_input_walk_right = utils.is_input_action_pressed(_control, "right")
	_input_jump = utils.is_input_action_pressed(_control, "jump")
	_input_hit = utils.is_input_action_pressed(_control, "hit")
	_input_special = utils.is_input_action_pressed(_control, "special")
	if input_walk_left_just_pressed() || input_walk_right_just_pressed():
		_can_run += 1
		_node_timer_run.stop()
		_node_timer_run.start()

func input_jump_just_pressed():
	return _input_jump && !_input_jump_prev

func input_hit_just_pressed():
	return _input_hit && !_input_hit_prev

func input_special_just_pressed():
	return _input_special && !_input_special_prev

func input_walk_left_just_pressed():
	return _input_walk_left && !_input_walk_left_prev

func input_walk_right_just_pressed():
	return _input_walk_right && !_input_walk_right_prev

func reset_offensive_hitboxes():
	for child in get_node("offensive_hitbox_areas").get_children():
		child.set_enable_monitoring(false)

func can_special():
	return _attributes.specials > 0

func check_items_to_consume():
	if _pickables.size() > 0:
		for key in _pickables.keys():
			var wkRef = _pickables[key]
			if wkRef.get_ref() != null:
				wkRef.get_ref().consume(self)
				remove_pickable(key)
				break

func signal_state_changed():
	emit_signal("state_changed", self)

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
		motion = n.slide(motion)
		_velocity = n.slide(_velocity)
		motion = move(motion)
	if new_touch_floor != null:
		_touch_floor = new_touch_floor

func end_hit():
	_hitting = false
	
func get_hit(hitter, power, knock_down):
	_hits_received.push_back([hitter, power, knock_down])

func recovered_hit():
	_recovered_hit = true

func get_up():
	_got_up = true

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
		signal_state_changed()
		bgms.play("game_over")
	else:
		respawn()

func respawn():
	_attributes.hp = MAX_HP
	_attributes.specials = globals.INIT_SPECIALS
	_touch_floor = false
	change_state(globals.STATE.FALL)
	_current_left = -1
	_velocity = Vector2(0, 0)
	set_scale(Vector2(_current_left, 1))
	_invincibility_cnt = RESPAWN_INVINCIBILITY_TIME
	_speed = WALK_SPEED
	defensive_hitbox(false)
	_node_anim_invincible.play("invincible")
	set_pos(Vector2(get_pos().x, -200))
	signal_state_changed()

func get_specials():
	return _attributes.specials

func check_invincible(delta):
	if _invincibility_cnt > 0:
		_invincibility_cnt -= delta
		if _invincibility_cnt <= 0:
			_invincibility_cnt = 0
			defensive_hitbox(true)
			_node_anim_invincible.stop()
			_node_sprite.set_opacity(1)

func defensive_hitbox(active):
	if !active || _invincibility_cnt == 0:
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
	_special_setup = true

func add_special(nb_specials):
	_attributes.specials += nb_specials
	_node_sound.play("special_charge")
	emit_signal("state_changed", self)

func set_hp(hp):
	_attributes.hp = hp

func lose_hp(hp):
	_attributes.hp -= hp
	if _attributes.hp < 0:
		_attributes.hp = 0

func set_freeze(freeze):
	if freeze:
		_freeze_old_state = _state
		change_state(globals.STATE.FREEZE)
	elif _freeze_old_state != null:
		change_state(_freeze_old_state)

func set_specials(specials):
	_attributes.specials = specials

func add_spark(area):
	var spark = preload_spark.instance()
	var pos = Vector2()
	pos.x = (area.get_global_pos().x + _node_offensive_hitbox_area1.get_global_pos().x) / 2
	pos.y = (area.get_global_pos().y + _node_offensive_hitbox_area1.get_global_pos().y) / 2
	spark.set_pos(pos)
	spark.set_scale(Vector2(_current_left, 1))
	get_node("../../").add_child(spark)

func hit_enemy(area):
	var enemy = area.get_node("../")
	enemy.get_hit(self, _power, _knock_down)
	_last_hit_connect = true
	if _knock_down:
		_node_sound.play("punch_02")
	else:
		_node_sound.play("punch_01")
	add_spark(area)

func _on_1_area_enter( area ):
	hit_enemy(area)

func _on_2_area_enter( area ):
	hit_enemy(area)

func _on_3_area_enter( area ):
	hit_enemy(area)

func _on_4_area_enter( area ):
	hit_enemy(area)

func _on_timer_combo_timeout():
	_combo_expired = true

func _on_timer_run_timeout():
	_can_run = 0
