extends Node

const INPUT_HIT = "hit"
const INPUT_LEFT = "ui_left"
const INPUT_RIGHT = "ui_right"
const INPUT_JUMP = "jump"
const INPUT_SPECIAL = "special"

const DEFAULT_SHAKE_MAGNITUDE = 2
const DEFAULT_SHAKE_DURATION = 0.2
const BOSS_DIE_SHAKE_MAGNITUDE = 5
const BOSS_DIE_SHAKE_DURATION = 0.4

# Angle in degrees towards either side that the player can consider "floor"
const FLOOR_ANGLE_TOLERANCE = 40
const GRAVITY = 500.0

enum STATE {
	IDLE,
	WALK,
	RUN,
	HIT,
	SPECIAL,
	BEING_HIT,
	KNOCKED_DOWN,
	KO,
	JUMP,
	JUMP_HIT
	FALL
}

var score =  {
	"p1": 0,
	"p2": 0
}

var p1_control = "keyboard" setget set_p1_control, get_p1_control
var p2_control = "joypad" setget set_p2_control, get_p2_control
var nb_players = 1 setget set_nb_players, get_nb_players

func set_nb_players(value):
	nb_players = value

func get_nb_players():
	return nb_players

func set_p1_control(value):
	p1_control = value

func get_p1_control():
	return p1_control

func set_p2_control(value):
	p2_control = value

func get_p2_control():
	return p2_control

func add_score(p, value):
	score[p] += value

func get_score(p):
	return score[p]

func _ready():
	pass