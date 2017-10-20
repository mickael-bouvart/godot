extends KinematicBody2D

func _ready():
	get_node("anim").play("hit_01")
	set_fixed_process(true)

func _fixed_process(delta):
	move(Vector2(1, 0))