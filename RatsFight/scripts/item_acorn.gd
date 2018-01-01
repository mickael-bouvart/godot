extends RigidBody2D

func _ready():
	get_node("anim").play("blink")
	pass

func _on_pickable_area_body_enter( body ):
	print("_on_pickable_area_body_enter")
	body.get_node("..").add_pickable(self)

func _on_pickable_area_body_exit( body ):
	print("_on_pickable_area_body_exit")
	body.get_node("..").remove_pickable(self)

func consume(consumer):
	consumer.restore_hp(5)
	queue_free()