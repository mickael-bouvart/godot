###############################################################################
# char1_ia.gd
# First basic IA for char1
#
# Behavior: Get near the hero1, and hit every HIT_INTERVAL seconds
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

func update_hero_scan(delta):
	_time_cnt_hero_scan -= delta
	if _time_cnt_hero_scan <= 0:
		_time_cnt_hero_scan = HERO_SCAN_INTERVAL
		_hero = utils.get_nearest_hero(_char.get_pos())
	
func is_near_hero():
	var dist = abs(_char.get_pos().x - _hero.get_pos().x)
	return dist < NEAR_HERO_MIN_DISTANCE

func follow_hero(delta):
	if _char.can_walk():
		_char.update_current_left(_hero)
		_char.walk_towards(_hero, delta)

func hit_hero(delta):
	if _char.can_hit():
		_time_cnt_hit -= delta
		if _time_cnt_hit <= 0:
			_time_cnt_hit = HIT_INTERVAL
			_char.hit()
		else:
			_char.stand()

func update(delta):
	update_hero_scan(delta)
	if is_near_hero():
		hit_hero(delta)
	else:
		follow_hero(delta)