extends KinematicBody2D

var SPEED = 30
var _velocity

func _ready():
	_velocity = Vector2(0, 0)
	set_fixed_process(true)
	pass

func _fixed_process(delta):
	if (get_pos().x > 1960 + 50) || (get_pos().x < 0 - 50):
		queue_free()
	move(_velocity)
	pass

func set_velocity(current_left):
	_velocity = Vector2(-current_left * SPEED, 0)