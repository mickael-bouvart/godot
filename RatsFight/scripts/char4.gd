extends KinematicBody2D

var preload_bullet = preload("res://scenes/bullet.tscn")
var _current_left = -1

func _ready():
	while (true):
		get_node("anim").play("hit_01")
		yield(get_node("anim"), "finished")
	pass

func shoot():
	var bullet = preload_bullet.instance()
	bullet.set_pos(get_pos() + Vector2(-_current_left * 160, 10))
	get_node("../").add_child(bullet)
	bullet.set_velocity(-1)
	pass