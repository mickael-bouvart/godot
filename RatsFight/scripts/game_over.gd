extends CanvasLayer

func _ready():
	set_process_input(true)

func show_game_over():
	get_node("frame").show()
	get_tree().set_pause(true)

func _input(event):
	if event.is_action_pressed(globals.p1_control + "_start")	\
	||  (globals.get_nb_players() > 1 && event.is_action_pressed(globals.p2_control + "_start")):
		bgms.stop()
		scene_manager.change_scene("res://scenes/Intro/Ninjardin.tscn")