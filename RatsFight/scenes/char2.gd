extends KinematicBody2D

func _fixed_process(delta):
	#set_pos(get_pos() + Vector2(-0.5, 0))
	move(Vector2(0.5, 0))
	if (getting_hit):
		get_node("anim").play("being_hit")
		getting_hit = false

var getting_hit = false
func get_hit():
	getting_hit = true

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_node("anim").play("hit_01")
	set_fixed_process(true)
	pass

func recovered_hit():
	get_node("anim").play("stand")