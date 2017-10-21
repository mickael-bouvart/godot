extends Node

func _ready():
	var hero1 = get_tree().get_root().get_node("Main").get_node("hero1")
	if (hero1):
		hero1.connect("state_changed", self, "_on_hero1_state_changed")
	_on_hero1_state_changed(hero1)
	pass

func _on_hero1_state_changed(hero1):
	print("_on_hero1_state_changed")
	get_node("CanvasLayer/label_lives").set_text(str(hero1.get_life()))