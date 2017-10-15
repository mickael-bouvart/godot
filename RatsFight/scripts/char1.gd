extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var SPEED = 4
var current_anim = null
var current_left = null
var state = null
var dir = 0

enum STATE {
	HIT,
	WALK_LEFT,
	WALK_RIGHT,
	BEING_HIT,
	IDLE
}

func _fixed_process(delta):
	var action_hit = Input.is_action_pressed("ui_accept")
	var walk_left = Input.is_action_pressed("ui_left")
	var walk_right = Input.is_action_pressed("ui_right")
	var new_anim = null
	var new_left = null
	
	#if (!action_hit && get_node("offensive_hitbox_area").is_monitoring_enabled()):
	#	get_node("offensive_hitbox_area").set_enable_monitoring(false)
	
	if (action_hit):
		if (state == STATE.IDLE || state == STATE.WALK_LEFT || state == STATE.WALK_RIGHT):
			new_anim = "hit"
			state = STATE.HIT
			dir = 0
	elif (walk_right):
		if (state == STATE.IDLE || state == STATE.WALK_LEFT):
			new_left = -1
			new_anim = "walk"
			dir = 1
			state = STATE.WALK_RIGHT
	elif walk_left:
		if (state == STATE.IDLE || state == STATE.WALK_RIGHT):
			new_left = 1
			new_anim = "walk"
			dir = -1
			state = STATE.WALK_LEFT
	else:
		if (state == STATE.WALK_LEFT || state == STATE.WALK_RIGHT):
			new_anim = "stand"
			state = STATE.IDLE
			dir = 0
	
	if (new_left != null && new_left != current_left):
		set_scale(Vector2(new_left, 1))
		current_left = new_left
		
	if (new_anim != null):
		get_node("anim").play(new_anim)
		current_anim = new_anim
	
	if (dir != 0):
		#set_pos(get_pos() + Vector2(dir * SPEED, 0))
		move(Vector2(dir * SPEED, 0))
		
	pass

func _ready():
	current_anim = "stand"
	current_left = -1
	state = STATE.IDLE
	set_scale(Vector2(current_left, 1))
	get_node("anim").play(current_anim)
	set_fixed_process(true)
	pass


func _on_offensive_hitbox_area_area_enter( area ):
	print("_on_offensive_hitbox_area_area_enter")
	var enemy = area.get_node("../")
	enemy.get_hit()
	get_node("sound").play("punch_01")
	pass # replace with function body


func _on_defensive_hitbox_area_area_exit( area ):
	print("_on_defensive_hitbox_area_area_exit")
	print(area)
	pass # replace with function body

func _on_defensive_hitbox_area_area_enter( area ):
	print("_on_defensive_hitbox_area_area_enter")
	pass # replace with function body

func _on_offensive_hitbox_area_area_exit( area ):
	print("_on_offensive_hitbox_area_area_exit")
	pass # replace with function body

func end_hit():
	state = STATE.IDLE