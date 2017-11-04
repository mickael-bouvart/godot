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

var score =  {
	"p1": 0,
	"p2": 0
}

func add_score(p, value):
	score[p] += value

func get_score(p):
	return score[p]

func _ready():
	pass