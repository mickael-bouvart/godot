extends KinematicBody2D

signal signal_dead

const FLOOR_ANGLE_TOLERANCE = 40
const MAX_LIFE = 5
const GRAVITY = 500.0
const WALK_SPEED = 100
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

func pattern_hit(frame, duration):
	if (state == STATE.IDLE):
		_power = 1
		_knock_down = false
		state = STATE.HIT
		get_node("anim").play("hit")

func pattern_stand(frame, duration):
	pass

func pattern_follow(frame, duration):
	var hero1 = get_tree().get_root().get_node("Main/hero1")
	var hero1_pos = hero1.get_pos().x
	var self_pos = get_pos().x
	var dist = abs(hero1_pos - self_pos)
	#print("Distance: " + str(dist))
	if (dist > MIN_DISTANCE_FOLLOW):
		if (state == STATE.IDLE || state == STATE.WALK):
			velocity.x = -current_left * WALK_SPEED
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

func _fixed_process(delta):
	# disable offensive hitbox area in case attack animation got interrupted
	if (state != STATE.HIT && get_node("offensive_hitbox_area").is_monitoring_enabled()):
		get_node("offensive_hitbox_area").set_enable_monitoring(false)
	
	if state == STATE.IDLE || state == STATE.WALK:
		var hero1 = get_tree().get_root().get_node("Main/hero1")
		var new_left = null
		if (get_pos().x < hero1.get_pos().x):
			new_left = -1
		else:
			new_left = 1
		if (new_left != null && new_left != current_left):
			print("Switching direction: " + str(new_left))
			set_scale(Vector2(new_left, 1))
			current_left = new_left
	
	var force = Vector2(0, GRAVITY)
	
	# Integrate forces to velocity
	velocity += force*delta
	# Integrate velocity into motion and move
	var motion = velocity*delta	
	motion = move(motion)
	
	if (is_colliding()):
		var n = get_collision_normal()
		if ![STATE.BEING_HIT, STATE.KO].has(state):
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
	pass

func get_hit(power, knock_down):
	velocity = Vector2(0, 0)
	life -= power
	if (life <= 0):
		velocity = Vector2(current_left * WALK_SPEED, -200)
		get_node("anim").play("ko")
		state = STATE.KO
	elif !knock_down:
		get_node("anim").play("being_hit")
		state = STATE.BEING_HIT
	else:
		velocity = Vector2(current_left * WALK_SPEED, -200)
		get_node("anim").play("knock_down")
		state = STATE.BEING_HIT
func _ready():
	current_pattern = patterns[2]
	life = MAX_LIFE
	state = STATE.IDLE
	get_node("anim").play("stand")
	current_left = null
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
	emit_signal("signal_dead")
	queue_free()

func _on_offensive_hitbox_area_area_enter( area ):
	var player = area.get_node("../")
	player.get_hit(_power, _knock_down)
	get_node("sound").play("punch_01")
	
func end_hit():
	state = STATE.IDLE
	get_node("anim").play("stand")
	
func get_up():
	velocity = Vector2(0, 0)
	state = STATE.IDLE
	get_node("anim").play("stand")