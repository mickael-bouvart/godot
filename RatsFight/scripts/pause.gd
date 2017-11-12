extends CanvasLayer

var _pause 

func _input(event):
	if event.is_action_pressed(globals.p1_control + "_start")	\
	||  (globals.get_nb_players() > 1 && event.is_action_pressed(globals.p2_control + "_start")):
		toggle_pause()

func toggle_pause():
	_pause = !_pause
	get_tree().set_pause(_pause)


func _ready():
	_pause = false
	set_process_input(true)
