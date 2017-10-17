extends KinematicBody2D

var MAX_LIFE = 5
var current_left = null

enum STATE {
	HIT,
	WALK_LEFT,
	WALK_RIGHT,
	BEING_HIT,
	IDLE,
	KO
}

var life = null
var state = null
var current_anim = null
var velocity = Vector2()
const GRAVITY = 500.0

var wait_count = 0

func _fixed_process(delta):
	# disable offensive hitbox area in case attack animation got interrupted
	if (state != STATE.HIT && get_node("offensive_hitbox_area").is_monitoring_enabled()):
		get_node("offensive_hitbox_area").set_enable_monitoring(false)
		
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
	
	if (state == STATE.IDLE):
		wait_count += 1
		if (wait_count % 200 == 0):
			state = STATE.HIT
			get_node("anim").play("hit_02")
	#move(Vector2(dir_x, dir_y + gravity))
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
	velocity = Vector2(current_left * 50, -600)
	
func hit_02_fall():
	velocity.y = 200
	pass
	
func hit_02_ground():
	velocity.x = 0
	get_node("anim").play("stand")
	state = STATE.IDLE