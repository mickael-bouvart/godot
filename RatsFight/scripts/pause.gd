extends CanvasLayer

var _pause 
var _freeze

func _input(event):
	if _freeze:
		return
	if event.is_action_pressed(globals.p1_control + "_start")	\
	||  (globals.get_nb_players() > 1 && event.is_action_pressed(globals.p2_control + "_start")):
		toggle_pause()

func toggle_pause():
	_pause = !_pause
	get_tree().set_pause(_pause)
	if _pause:
		get_node("frame").show()
	else:
		get_node("frame").hide()


func _ready():
	_pause = false
	set_process_input(true)

func set_freeze(freeze):
	_freeze = freeze