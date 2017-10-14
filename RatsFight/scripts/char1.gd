extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var SPEED = 2
var current_anim = null
var current_right = null

func _fixed_process(delta):
	var action_hit = Input.is_action_pressed("ui_accept")
	var walk_left = Input.is_action_pressed("ui_left")
	var walk_right = Input.is_action_pressed("ui_right")
	var new_anim = ""
	var new_right = null
	var dir = 0
	
	if (action_hit):
		new_anim = "hit"
	elif (walk_right):
		new_right = true
		new_anim = "walk"
		dir = 1
	elif walk_left:
		new_right = false
		new_anim = "walk"
		dir = -1
	else:
		new_anim = "stand"
	if (new_right != null && new_right != current_right):
		get_node("sprite").set_flip_h(new_right)
		current_right = new_right
		
	if (new_anim != current_anim):
		get_node("anim").play(new_anim)
		current_anim = new_anim
	
	if (dir != 0):
		move(Vector2(dir * SPEED, 0))
	
	pass

func _ready():
	current_anim = "stand"
	current_right = true
	get_node("anim").play(current_anim)
	set_fixed_process(true)
	pass
