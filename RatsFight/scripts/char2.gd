extends KinematicBody2D

const MAX_LIFE = 20
const GRAVITY = 500.0
const WALK_SPEED = 120
const HIT_02_JUMP_FORCE_X = 80
const HIT_02_JUMP_FORCE_Y = -600
const HIT_02_FALL_FORCE_Y = 200

enum STATE {
	HIT,
	WALK,
	BEING_HIT,
	IDLE,
	KO
}

var patterns = [
	{ "key": "STAND", "func": funcref(self, "pattern_stand"), "duration": 100, "prob": 30 },
	{ "key": "HIT_01", "func": funcref(self, "pattern_hit_01"), "duration": 100, "prob": 30 },
	{ "key": "HIT_02", "func": funcref(self, "pattern_hit_02"), "duration": 100, "prob": 10 },
	{ "key": "FOLLOW", "func": funcref(self, "pattern_follow"), "duration": 100, "prob": 30 }
]

var life = null
var state = null
var velocity = Vector2()
var current_left = null
var current_anim = null
var current_pattern = null
var pattern_duration_cnt = 0

func pattern_hit_01(frame, duration):
	if (state == STATE.IDLE):
		state = STATE.HIT
		get_node("anim").play("hit_01")

func pattern_hit_02(frame, duration):
	if (state == STATE.IDLE):
		state = STATE.HIT
		get_node("anim").play("hit_02")

func pattern_stand(frame, duration):
	pass

func pattern_follow(frame, duration):
	var char1 = get_node("../char1")
	var char1_pos = char1.get_pos().x
	var self_pos = get_pos().x
	var dist = abs(char1_pos - self_pos)
	#print("Distance: " + str(dist))
	if (dist > 300):
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
		print("STOP " + str(state))
		velocity.x = 0
		get_node("anim").play("stand")
		state = STATE.IDLE

func _fixed_process(delta):
	# disable offensive hitbox area in case attack animation got interrupted
	if (state != STATE.HIT && get_node("offensive_hitbox_area").is_monitoring_enabled()):
		get_node("offensive_hitbox_area").set_enable_monitoring(false)
	
	var char1 = get_node("../char1")
	var new_left = null
	if (get_pos().x < char1.get_pos().x):
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
		print("Switching to pattern " + current_pattern["key"])
	pass

func get_hit():
	velocity = Vector2(0, 0)
	life -= 1
	if (life == 0):
		get_node("anim").play("ko")
		state = STATE.KO
	else:
		get_node("anim").play("being_hit")
		state = STATE.BEING_HIT

func _ready():
	current_pattern = patterns[3]
	life = MAX_LIFE
	state = STATE.HIT
	get_node("anim").play("hit_01")
	current_left = -1
	set_fixed_process(true)
	pass

func recovered_hit():
	get_node("anim").play("stand")
	state = STATE.IDLE

func dead():
	queue_free()

func _on_offensive_hitbox_area_area_enter( area ):
	var player = area.get_node("../")
	player.get_hit()
	get_node("sound").play("punch_01")
	
func end_hit():
	state = STATE.IDLE
	get_node("anim").play("stand")

func hit_02_jump():
	velocity = Vector2(-current_left * HIT_02_JUMP_FORCE_X, HIT_02_JUMP_FORCE_Y)
	
func hit_02_fall():
	velocity.y = HIT_02_FALL_FORCE_Y
	
func hit_02_ground():
	velocity.x = 0
	get_node("anim").play("stand")
	state = STATE.IDLE