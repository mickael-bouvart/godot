extends Node

func _ready():
	pass

func get_hero1():
	return get_tree().get_root().get_node("Main/heroes").get_children()[0]

func get_hero2():
	var heroes = get_tree().get_root().get_node("Main/heroes").get_children()
	if heroes.size() < 2:
		return null
	return heroes[1]

func get_heroes():
	return get_tree().get_root().get_node("Main/heroes").get_children()

func get_nearest_hero(pos):
	var nearest_hero = null
	var nearest_dist = null
	var heroes = get_tree().get_root().get_node("Main/heroes").get_children()
	for hero in heroes:
		var dist = abs(hero.get_pos().x - pos.x)
		if nearest_dist == null || dist < nearest_dist:
			nearest_hero = hero
			nearest_dist = dist
	return nearest_hero

func get_camera():
	return get_hero1().get_node("camera")

func shake_camera(magnitude, duration):
	get_camera().shake(magnitude, duration)

func is_input_action_pressed(p, action):
	return Input.is_action_pressed(p + "_" + action)

func is_event_input_action_pressed(event, p, action):
	return event.is_action_pressed(p + "_" + action)

func switch_menu(current_menu, new_menu_path):
	var new_menu_load = load(new_menu_path)
	var new_menu = new_menu_load.instance()
	current_menu.hide()
	current_menu.get_node("../").add_child(new_menu)
	current_menu.queue_free()