extends KinematicBody2D

signal state_changed

const MAX_LIFE = 20
const GRAVITY = 500.0
const WALK_SPEED = 200

enum STATE {
	HIT,
	WALK,
	BEING_HIT,
	IDLE,
	KO
}

var _life
var _current_left
var _state
var _hit_released
var _velocity

onready var _node_anim = get_node("anim")
onready var _node_offensive_hitbox_area = get_node("offensive_hitbox_area")
onready var _node_sound = get_node("sound")

func _ready():
	set_fixed_process(true)
	_life = MAX_LIFE
	_hit_released = true
	_node_anim.play("stand")
	_current_left = -1
	_state = STATE.IDLE
	_velocity = Vector2(0, 0)
	set_scale(Vector2(_current_left, 1))

func _fixed_process(delta):
	var action_hit = Input.is_action_pressed("ui_accept")
	var walk_left = Input.is_action_pressed("ui_left")
	var walk_right = Input.is_action_pressed("ui_right")
	var new_left = null
	
	# disable offensive hitbox area in case animation got interrupted
	if (_state != STATE.HIT && _node_offensive_hitbox_area.is_monitoring_enabled()):
		_node_offensive_hitbox_area.set_enable_monitoring(false)
	
	if (!action_hit):
		_hit_released = true
	if (_hit_released && action_hit):
		_hit_released = false
		if (_state == STATE.IDLE || _state == STATE.WALK):
			_node_anim.play("hit_01")
			_state = STATE.HIT
			_velocity.x = 0
	elif (walk_right):
		if (_state == STATE.IDLE || (_state == STATE.WALK && _current_left == 1)):
			new_left = -1
			_node_anim.play("walk")
			_velocity.x = WALK_SPEED
			_state = STATE.WALK
	elif walk_left:
		if (_state == STATE.IDLE || (_state == STATE.WALK && _current_left == -1)):
			new_left = 1
			_node_anim.play("walk")
			_velocity.x = -WALK_SPEED
			_state = STATE.WALK
	else:
		if (_state == STATE.WALK):
			_node_anim.play("stand")
			_state = STATE.IDLE
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

func _on_defensive_hitbox_area_area_exit( area ):
	pass

func _on_defensive_hitbox_area_area_enter( area ):
	pass

func _on_offensive_hitbox_area_area_exit( area ):
	pass

func end_hit():
	_state = STATE.IDLE
	_node_anim.play("stand")
	
func get_hit():
	_velocity.x = 0
	_life -= 1
	if (_life == 0):
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

func get_max_life():
	return MAX_LIFE