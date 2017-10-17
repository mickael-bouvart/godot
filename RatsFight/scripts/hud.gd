extends Node

func _ready():
	var char1 = get_tree().get_root().get_node("Main").get_node("char1")
	if (char1):
		char1.connect("state_changed", self, "_on_char1_state_changed")
	_on_char1_state_changed(char1)
	pass

func _on_char1_state_changed(char1):
	print("_on_char1_state_changed")
	get_node("CanvasLayer/label_lives").set_text(str(char1.get_life()))