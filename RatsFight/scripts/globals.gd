extends Node

const INIT_SPECIALS = 2
const INIT_LIVES = 3
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
	FREEZE,
	IDLE,
	WALK,
	RUN,
	HIT,
	SPECIAL,
	BEING_HIT,
	KNOCKED_UP,
	KNOCKED_DOWN,
	KO,
	JUMP,
	JUMP_HIT
	FALL,
	GLIDE,
	SPECIAL_SETUP,
	SPECIAL_STEP_ONE,
	SPECIAL_STEP_TWO,
	SPECIAL_STEP_THREE
}

class PlayerAttributes:
	var score setget set_score, get_score
	var lives setget set_lives, get_lives
	var hp setget set_hp, get_hp
	var specials setget set_specials, get_specials
	
	func _init():
		lives = INIT_LIVES
		specials = INIT_SPECIALS
		score = 0
		hp = 0
		
	func set_score(val):
		score = val
	
	func get_score():
		return score
	
	func set_lives(val):
		lives = val
	
	func get_lives():
		return lives
	
	func set_hp(val):
		hp = val
	
	func get_hp():
		return hp
	
	func set_specials(val):
		specials = val
	
	func get_specials():
		return specials


var player_attributes =  {
	"p1": PlayerAttributes.new(),
	"p2": PlayerAttributes.new()
}

var p1_control = "keyboard" setget set_p1_control, get_p1_control
var p2_control = "joypad" setget set_p2_control, get_p2_control
var nb_players = 2 setget set_nb_players, get_nb_players

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
	player_attributes[p].score += value

func get_score(p):
	return player_attributes[p].score

func _ready():
	#AudioServer.set_stream_global_volume_scale(0)
	#AudioServer.set_fx_global_volume_scale(0)
	pass