extends KinematicBody2D

signal signal_dead

export var walk_speed = 100
export var max_hp = 5
export var _score = 50

const MIN_DISTANCE_FOLLOW = 200

enum STATE {
	HIT,
	WALK,
	BEING_HIT,
	IDLE,
	KO
}

var patterns = [
	{ "key": "STAND", "func": funcref(self, "pattern_stand"), "duration": 50, "prob": 20 },
	{ "key": "HIT", "func": funcref(self, "pattern_hit"), "duration": 100, "prob": 30 },
	{ "key": "FOLLOW", "func": funcref(self, "pattern_follow"), "duration": 100, "prob": 50 }
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

var _iapreload = preload("res://scripts/char1_ia.gd")
var _ia

func pattern_hit(frame, duration):
	if (state == STATE.IDLE):
		_power = 1
		_knock_down = false
		state = STATE.HIT
		get_node("anim").play("hit")

func pattern_stand(frame, duration):
	pass

func pattern_follow(frame, duration):
	var hero1 = utils.get_hero1()
	var hero1_pos = hero1.get_pos().x
	var self_pos = get_pos().x
	var dist = abs(hero1_pos - self_pos)
	#print("Distance: " + str(dist))
	if (dist > MIN_DISTANCE_FOLLOW):
		if (state == STATE.IDLE || state == STATE.WALK):
			velocity.x = -current_left * walk_speed
			if (state == STATE.IDLE):
				get_node("anim").play("walk")
				state = STATE.WALK
	elif (state == STATE.WALK):
		get_node("anim").play("stand")
		state = STATE.IDLE
		velocity.x = 0
		pattern_duration_cnt = duration - 1
		return
		
	#print(str(frame) + " / " + str(duration))
	if (frame == duration - 1 && state == STATE.WALK):
		velocity.x = 0
		get_node("anim").play("stand")
		state = STATE.IDLE

func update_current_left(hero = null):
	if hero == null:
		hero = utils.get_nearest_hero(get_pos())
	var new_left = null
	if (get_pos().x < hero.get_pos().x):
		new_left = -1
	else:
		new_left = 1
	if (new_left != null && new_left != current_left):
		print("Switching direction: " + str(new_left))
		set_scale(Vector2(new_left, 1))
		current_left = new_left

func _fixed_process(delta):
	# disable offensive hitbox area in case attack animation got interrupted
	if (state != STATE.HIT && get_node("offensive_hitbox_area").is_monitoring_enabled()):
		get_node("offensive_hitbox_area").set_enable_monitoring(false)
	
	if _ia:
		_ia.update(delta)
		apply_forces(delta)
		return
		
	if state == STATE.IDLE || state == STATE.WALK:
		update_current_left()
		
	apply_forces(delta)
	
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
	pass

func apply_forces(delta):
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
			if [STATE.BEING_HIT, STATE.KO, STATE.IDLE, STATE.HIT].has(state):
				motion.x = 0
		
		if ![STATE.IDLE, STATE.HIT, STATE.BEING_HIT, STATE.KO].has(state):
			motion = n.slide(motion)
			velocity = n.slide(velocity)
		motion = move(motion)

func get_hit(hero, power, knock_down):
	velocity = Vector2(0, 0)
	life -= power
	if (life <= 0):
		if hero:
			hero.add_score(_score)
		velocity = Vector2(current_left * walk_speed, -200)
		get_node("anim").play("ko")
		state = STATE.KO
	elif !knock_down:
		get_node("anim").play("being_hit")
		state = STATE.BEING_HIT
	else:
		get_node("defensive_hitbox_area").set_monitorable(false)
		velocity = Vector2(current_left * walk_speed, -200)
		get_node("anim").play("knock_down")
		state = STATE.BEING_HIT

func _ready():
	#_ia = null
	_ia = _iapreload.new(self)
	get_node("defensive_hitbox_area").set_monitorable(true)
	current_pattern = patterns[2]
	life = max_hp
	state = STATE.IDLE
	get_node("anim").play("stand")
	update_current_left()
	var r = (randi() % 200 + 55) / 255.0
	var g = (randi() % 200 + 55) / 255.0
	var b = (randi() % 200 + 55) / 255.0
	get_node("sprite").set_modulate(Color(r, g, b, 1.0))
	set_fixed_process(true)
	pass

func recovered_hit():
	get_node("anim").play("stand")
	state = STATE.IDLE

func dead():
	emit_signal("signal_dead", self)
	queue_free()

func _on_offensive_hitbox_area_area_enter( area ):
	var player = area.get_node("../")
	player.get_hit(_power, _knock_down)
	get_node("sound").play("punch_01")

func end_hit():
	state = STATE.IDLE
	get_node("anim").play("stand")

func get_up():
	# Concurrency issue when get_hit is called at the same time as get_up
	if life <= 0:
		return
	get_node("defensive_hitbox_area").set_monitorable(true)
	velocity = Vector2(0, 0)
	state = STATE.IDLE
	get_node("anim").play("stand")

func set_walk_speed(new_walk_speed):
	walk_speed = new_walk_speed

func connect_dead(receiver, callback):
	connect("signal_dead", receiver, callback)

func set_score(score):
	_score = score

func can_walk():
	return [STATE.IDLE, STATE.WALK].has(state)

func walk_towards(hero, delta):
	var dir = 1 if get_pos().x < hero.get_pos().x else -1 
	velocity.x = dir * walk_speed
	if state != STATE.WALK:
		state = STATE.WALK
		get_node("anim").play("walk")

func can_hit():
	return [STATE.IDLE, STATE.WALK].has(state)

func hit():
	velocity.x = 0
	state = STATE.HIT
	_power = 1
	_knock_down = false
	get_node("anim").play("hit")

func stand():
	if state != STATE.IDLE:
		state = STATE.IDLE
		get_node("anim").play("stand")

func get_current_left():
	return current_left

func walk_away_from(hero, delta):
	var dir = -1 if get_pos().x < hero.get_pos().x else 1 
	velocity.x = dir * walk_speed
	if state != STATE.WALK:
		state = STATE.WALK
		get_node("anim").play("walk")