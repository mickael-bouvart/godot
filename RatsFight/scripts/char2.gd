extends KinematicBody2D

signal signal_dead

const MAX_LIFE = 40
const WALK_SPEED = 300
const HIT_02_JUMP_FORCE_X = 80
const HIT_02_JUMP_FORCE_Y = -600
const HIT_02_FALL_FORCE_Y = 200
const MIN_DISTANCE_FOLLOW = 200

var patterns = [
	{ "key": "STAND", "func": funcref(self, "pattern_stand"), "duration": 50, "prob": 0 },
	{ "key": "HIT_01", "func": funcref(self, "pattern_hit_01"), "duration": 100, "prob": 20 },
	{ "key": "HIT_02", "func": funcref(self, "pattern_hit_02"), "duration": 30, "prob": 10 },
	{ "key": "FOLLOW", "func": funcref(self, "pattern_follow"), "duration": 100, "prob": 70 }
]

var life = null
var state = null
var velocity = Vector2()
var current_left = null
var current_anim = null
var current_pattern = null
var pattern_duration_cnt = 0
var _power
var _knock_down
var _touch_floor = false

export var _score = 2000

func pattern_hit_01(frame, duration):
	if (state == globals.STATE.IDLE):
		_power = 1
		_knock_down = false
		state = globals.STATE.HIT
		get_node("anim").play("hit_01")

func pattern_hit_02(frame, duration):
	if (state == globals.STATE.IDLE):
		_power = 5
		_knock_down = true
		state = globals.STATE.HIT
		get_node("sound").play("special_charge")
		get_node("defensive_hitbox_area").set_monitorable(false)
		get_node("anim").play("hit_02")

func pattern_stand(frame, duration):
	pass

func pattern_follow(frame, duration):
	var hero1 = utils.get_nearest_hero(get_pos())
	var hero1_pos = hero1.get_pos().x
	var self_pos = get_pos().x
	var dist = abs(hero1_pos - self_pos)
	#print("Distance: " + str(dist))
	if (dist > MIN_DISTANCE_FOLLOW):
		if (state == globals.STATE.IDLE || state == globals.STATE.WALK):
			velocity.x = -current_left * WALK_SPEED
			if (state == globals.STATE.IDLE):
				get_node("anim").play("walk")
				state = globals.STATE.WALK
	else:
		if (state == globals.STATE.WALK):
			get_node("anim").play("stand")
			state = globals.STATE.IDLE
			velocity.x = 0
		pattern_duration_cnt = duration - 1
		return
		
	#print(str(frame) + " / " + str(duration))
	if (frame == duration - 1 && state == globals.STATE.WALK):
		#print("STOP " + str(state))
		velocity.x = 0
		get_node("anim").play("stand")
		state = globals.STATE.IDLE

func _fixed_process(delta):
	# disable offensive hitbox area in case attack animation got interrupted
	if (state != globals.STATE.HIT && get_node("offensive_hitbox_area").is_monitoring_enabled()):
		get_node("offensive_hitbox_area").set_enable_monitoring(false)
	
	if state == globals.STATE.IDLE || state == globals.STATE.WALK:
		var hero1 = utils.get_nearest_hero(get_pos())
		var new_left = null
		if (get_pos().x < hero1.get_pos().x):
			new_left = -1
		else:
			new_left = 1
		if (new_left != null && new_left != current_left):
			#print("Switching direction: " + str(new_left))
			set_scale(Vector2(new_left, 1))
			current_left = new_left
	var force = Vector2(0, globals.GRAVITY)
	
	# Integrate forces to velocity
	velocity += force*delta
	# Integrate velocity into motion and move
	var motion = velocity*delta	
	motion = move(motion)
	
	if (is_colliding()):
		var n = get_collision_normal()
		# touch the floor
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < globals.FLOOR_ANGLE_TOLERANCE):
			_touch_floor = true
			if [globals.STATE.KNOCKED_DOWN, globals.STATE.BEING_HIT, globals.STATE.KO, globals.STATE.IDLE, globals.STATE.HIT].has(state):
				motion.x = 0
		if ![globals.STATE.KNOCKED_DOWN, globals.STATE.BEING_HIT, globals.STATE.KO].has(state):
			motion = n.slide(motion)
			velocity = n.slide(velocity)
		motion = move(motion)
	current_pattern["func"].call_func(pattern_duration_cnt, current_pattern.duration)
	pattern_duration_cnt += 1
	if (pattern_duration_cnt == current_pattern["duration"]):
		pattern_duration_cnt = 0
		var rand = randi() % 100
		var cumul = 0
		for p in patterns:
			if (rand < cumul + p["prob"]):
				current_pattern = p
				break
			cumul += p["prob"]
		#print("Switching to pattern " + current_pattern["key"])
	check_get_hit()
	pass

func check_get_hit():
	if [globals.STATE.KNOCKED_UP, globals.STATE.KNOCKED_UP_HIT_ALL].has(state) && _touch_floor:
		if life <= 0:
			state = globals.STATE.KO
			get_node("anim").play("ko")
		else:
			state = globals.STATE.KNOCKED_DOWN
			get_node("anim").play("knock_down")

func get_hit(hero, power, knock_down):
	velocity = Vector2(0, 0)
	life -= power
	if (life <= 0):
		if hero:
			hero.add_score(_score)
		_touch_floor = false
		velocity = Vector2(current_left * WALK_SPEED, -200)
		get_node("defensive_hitbox_area").set_monitorable(false)
		get_node("anim").play("knock_up")
		state = globals.STATE.KNOCKED_UP
	elif !knock_down:
		get_node("anim").play("being_hit")
		state = globals.STATE.BEING_HIT
	else:
		_touch_floor = false
		velocity = Vector2(current_left * WALK_SPEED, -200)
		get_node("defensive_hitbox_area").set_monitorable(false)
		get_node("anim").play("knock_up")
		state = globals.STATE.KNOCKED_UP

func _ready():
	get_node("defensive_hitbox_area").set_monitorable(true)
	current_pattern = patterns[3]
	life = MAX_LIFE
	state = globals.STATE.IDLE
	get_node("anim").play("stand")
	current_left = null
	set_fixed_process(true)
	pass

func recovered_hit():
	get_node("anim").play("stand")
	state = globals.STATE.IDLE

func dead():
	emit_signal("signal_dead", self)
	queue_free()

func _on_offensive_hitbox_area_area_enter( area ):
	var player = area.get_node("../../")
	player.get_hit(self, _power, _knock_down)
	if _knock_down:
		get_node("sound").play("punch_04")
	else:
		get_node("sound").play("punch_01")

func end_hit():
	state = globals.STATE.IDLE
	get_node("anim").play("stand")

func get_up():
	velocity = Vector2(0, 0)
	state = globals.STATE.IDLE
	get_node("defensive_hitbox_area").set_monitorable(true)
	get_node("anim").play("stand")

func hit_02_jump():
	velocity = Vector2(-current_left * HIT_02_JUMP_FORCE_X, HIT_02_JUMP_FORCE_Y)
	
func hit_02_fall():
	velocity.y = HIT_02_FALL_FORCE_Y
	
func hit_02_ground():
	velocity.x = 0
	get_node("defensive_hitbox_area").set_monitorable(true)
	get_node("anim").play("stand")
	state = globals.STATE.IDLE

func shake_camera():
	utils.shake_camera(globals.BOSS_DIE_SHAKE_MAGNITUDE, globals.BOSS_DIE_SHAKE_DURATION)

func connect_dead(receiver, callback):
	connect("signal_dead", receiver, callback)