###############################################################################
# char1_ia.gd
# First basic IA for char1
#
# Behavior: Get near the hero1, and hit at regular interval
###############################################################################

extends Node

const HERO_SCAN_INTERVAL = 2
const HIT_INTERVAL = 1
const NEAR_HERO_MIN_DISTANCE = 200

var _char
var _time_cnt_hero_scan
var _hero
var _time_cnt_hit

func _init(char):
	_char = char
	_time_cnt_hero_scan = 0
	_time_cnt_hit = 0

func check_hero():
	if _hero == null || _hero.get_ref() == null:
		hero_scan()

func hero_scan():
	_time_cnt_hero_scan = HERO_SCAN_INTERVAL
	_hero = weakref(utils.get_nearest_hero(_char.get_pos()))

func update_hero_scan(delta):
	_time_cnt_hero_scan -= delta
	if _time_cnt_hero_scan <= 0:
		hero_scan()

func is_near_hero():
	var dist = abs(_char.get_pos().x - _hero.get_ref().get_pos().x)
	return dist < NEAR_HERO_MIN_DISTANCE

func follow_hero(delta):
	if _char.can_walk():
		_char.update_current_left(_hero.get_ref())
		_char.walk_towards(_hero.get_ref(), delta)

func hit_hero(delta):
	if _char.can_hit():
		_char.update_current_left(_hero.get_ref())
		_time_cnt_hit -= delta
		if _time_cnt_hit <= 0:
			_time_cnt_hit = HIT_INTERVAL
			_char.hit()
		else:
			_char.stand()

func update(delta):
	check_hero()
	_char.check_get_hit()
	update_hero_scan(delta)
	if is_near_hero():
		hit_hero(delta)
	else:
		follow_hero(delta)