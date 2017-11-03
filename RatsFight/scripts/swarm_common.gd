extends Node

signal signal_clear

export var camera_limit = 0
export var bgm = ""

var _nb_enemies
var _count_dead

func _ready():
	_count_dead = 0
	_nb_enemies = get_children().size()
	for child in get_children():
		child.connect_dead(self, "one_dead")

func one_dead(char):
	if char.is_in_group("spawned"):
		return
	if char.is_in_group("boss"):
		for child in get_children():
			if child.is_in_group("simple_enemy"):
				child.get_hit(9999, true)
	_count_dead += 1
	if _count_dead == _nb_enemies:
		emit_signal("signal_clear")
		queue_free()
		
func get_camera_limit():
	return camera_limit

func get_bgm():
	return bgm