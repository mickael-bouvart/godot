extends Node

var _hp_bar_initial_width

func _ready():
	var hero1 = get_tree().get_root().get_node("Main/hero1")
	var hero2 = get_tree().get_root().get_node("Main/hero2")
	_hp_bar_initial_width = get_node("CanvasLayer/Panel/p1/current_hp_bar").get_size().x
	if (hero1):
		hero1.connect("state_changed", self, "_on_hero_state_changed")
		_on_hero_state_changed(hero1)
	if (hero2):
		hero2.connect("state_changed", self, "_on_hero_state_changed")
		_on_hero_state_changed(hero2)
	else:
		get_node("CanvasLayer/Panel/p2").hide()
	pass

func _on_hero_state_changed(hero):
	print("_on_hero_state_changed")
	var p = hero.get_player()
	var hp_ratio = float(hero.get_hp()) / float(hero.get_max_hp())
	get_node("CanvasLayer/Panel/" + p + "/current_hp_bar").set_size(Vector2(hp_ratio * _hp_bar_initial_width, get_node("CanvasLayer/Panel/" + p + "/current_hp_bar").get_size().y))
	get_node("CanvasLayer/Panel/" + p + "/label_lives").set_text(str(hero.get_life()))
	get_node("CanvasLayer/Panel/" + p + "/label_specials").set_text(str(hero.get_special()))
	get_node("CanvasLayer/Panel/" + p + "/label_score").set_text("%010d" % hero.get_score())