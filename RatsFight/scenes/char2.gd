extends KinematicBody2D

var MAX_LIFE = 5

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

func _fixed_process(delta):
	if (state == STATE.IDLE):
		state = STATE.HIT
		get_node("anim").play("hit_01")
	pass

func get_hit():
	life -= 1
	if (life == 0):
		get_node("anim").play("ko")
		state = STATE.KO
	else:
		get_node("anim").play("being_hit")
		state = STATE.BEING_HIT

func _ready():
	life = MAX_LIFE
	state = STATE.IDLE
	get_node("anim").play("stand")
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
