extends Node

var _hp_bar_initial_width

func _ready():
	var hero1 = get_tree().get_root().get_node("Main").get_node("hero1")
	_hp_bar_initial_width = get_node("CanvasLayer/Panel/current_hp_bar").get_size().x
	if (hero1):
		hero1.connect("state_changed", self, "_on_hero1_state_changed")
	_on_hero1_state_changed(hero1)
	pass

func _on_hero1_state_changed(hero1):
	print("_on_hero1_state_changed")
	var hp_ratio = float(hero1.get_hp()) / float(hero1.get_max_hp())
	get_node("CanvasLayer/Panel/current_hp_bar").set_size(Vector2(hp_ratio * _hp_bar_initial_width, get_node("CanvasLayer/Panel/current_hp_bar").get_size().y))
	get_node("CanvasLayer/Panel/label_lives").set_text(str(hero1.get_life()))