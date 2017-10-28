extends KinematicBody2D

const GRAVITY = 500
const DRIVE_SPEED = 800

var _power = 2
var _knock_down = true

var char1_preload = preload("res://scenes/char1.tscn")

var _velocity = Vector2()

func _ready():
	_velocity = Vector2(-DRIVE_SPEED, 0)
	get_node("anim").play("drive_bike")
	set_fixed_process(true)
	pass

func _fixed_process(delta):
	var force = Vector2(0, GRAVITY)
	# Integrate forces to velocity
	_velocity += force*delta
	# Integrate velocity into motion and move
	var motion = _velocity*delta	
	motion = move(motion)
	if (is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		_velocity = n.slide(_velocity)
		motion = move(motion)
	#var n = get_node("offensive_hitbox_area")
	#print("Monitoring: " + str(n.is_monitoring_enabled()))
	pass

func get_hit(power, knock_down):
	var char1 = char1_preload.instance()
	char1.set_pos(get_pos())
	get_node("../").add_child(char1)
	char1.get_hit(power, true)
	queue_free()
	pass

func _on_offensive_hitbox_area_area_enter( area ):
	print("_on_offensive_hitbox_area_area_enter")
	var player = area.get_node("../")
	player.get_hit(_power, _knock_down)
	get_node("sound").play("punch_01")