extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
func _fixed_process(delta):
	move(Vector2(-2, 0))


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	get_node("anim").play("hit_02")
	set_fixed_process(true)
	pass
