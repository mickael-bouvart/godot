extends Node

const DEFAULT_SHAKE_MAGNITUDE = 2
const DEFAULT_SHAKE_DURATION = 0.2
const BOSS_DIE_SHAKE_MAGNITUDE = 5
const BOSS_DIE_SHAKE_DURATION = 0.4

func _ready():
	pass

func get_hero1():
	return get_tree().get_root().get_node("Main/hero1")

func get_camera():
	return get_hero1().get_node("camera")

func shake_camera(magnitude, duration):
	get_camera().shake(magnitude, duration)