extends RigidBody2D

func _ready():
	get_node("anim").play("blink")
	pass

func _on_pickable_area_body_enter( body ):
	print("_on_pickable_area_body_enter")
	body.add_pickable(self)

func _on_pickable_area_body_exit( body ):
	print("_on_pickable_area_body_exit")
	body.remove_pickable(self)

func consume(consumer):
	consumer.add_special(1)
	queue_free()