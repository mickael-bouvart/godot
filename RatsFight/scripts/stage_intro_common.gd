extends Node

signal action

func _ready():
	pass

func _on_timer_timeout():
	get_node("anim").play("transition")
	get_node("anim").connect("finished", self, "action")

func action():
	emit_signal("action")
	queue_free()