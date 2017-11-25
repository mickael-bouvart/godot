extends Camera2D

var _duration
var _magnitude

func _ready():
	_duration = 0
	_magnitude = 0
	set_fixed_process(true)

func _fixed_process(delta):
	if _duration > 0:
		_duration -= delta
		var shake = Vector2()
		shake.x = rand_range(-_magnitude, _magnitude)
		shake.y = 0#rand_range(-_magnitude, _magnitude)
		set_offset(shake)
	elif get_offset() != Vector2(0, 0):
		set_offset(Vector2(0, 0))
	pass

func shake(magnitude, duration):
	_duration = duration
	_magnitude = magnitude