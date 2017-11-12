###############################################################################
# char1_ia3.gd
# Second basic IA for char1
#
# Behavior:
#	Altern between the following: 
# - Rush towards hero
# - Keep distance
###############################################################################

extends Node

const HERO_SCAN_INTERVAL = 2
const HIT_INTERVAL = 1
const NEAR_HERO_MIN_DISTANCE = 200
const KEEP_HERO_DISTANCE = 500
const BEHAVIOR_SWITCH_INTERVAL = 5

var _char
var _time_cnt_hero_scan
var _hero
var _time_cnt_hit
var _time_cnt_switch
var _behavior

func _init(char):
	_char = char
	_time_cnt_hero_scan = 0
	_time_cnt_hit = 0
	_time_cnt_switch = rand_range(0, BEHAVIOR_SWITCH_INTERVAL)
	_behavior = 0

func update_hero_scan(delta):
	_time_cnt_hero_scan -= delta
	if _time_cnt_hero_scan <= 0:
		_time_cnt_hero_scan = HERO_SCAN_INTERVAL
		_hero = utils.get_nearest_hero(_char.get_pos())

func get_distance_from_hero():
	return abs(_char.get_pos().x - _hero.get_pos().x)

func is_near_hero():
	var dist = get_distance_from_hero()
	return dist < NEAR_HERO_MIN_DISTANCE

func is_around(current_dist, expected_dist, allowed_diff):
	return abs(current_dist - expected_dist) < allowed_diff

func follow_hero_direct(delta):
	if _char.can_walk():
		_char.update_current_left(_hero)
		_char.walk_towards(_hero, delta)

func follow_hero_indirect(delta):
	if _char.can_walk():
		_char.update_current_left(_hero)
		var dist = get_distance_from_hero()
		if is_around(dist, KEEP_HERO_DISTANCE, 50):
			_char.stand()
		elif dist < KEEP_HERO_DISTANCE:
			_char.walk_away_from(_hero, delta)
		else:
			_char.walk_towards(_hero, delta)

func hit_hero(delta):
	if _char.can_hit():
		_time_cnt_hit -= delta
		if _time_cnt_hit <= 0:
			_time_cnt_hit = HIT_INTERVAL
			_char.hit()
		else:
			_char.update_current_left(_hero)
			_char.stand()

func check_behavior_switch(delta):
	_time_cnt_switch -= delta
	if _time_cnt_switch <= 0:
		print("SWITCH")
		_time_cnt_switch = BEHAVIOR_SWITCH_INTERVAL
		_behavior = (_behavior + 1) % 2

func update(delta):
	update_hero_scan(delta)
	check_behavior_switch(delta)
	if _behavior == 0:
		follow_hero_indirect(delta)
	else:
		if is_near_hero():
			hit_hero(delta)
		else:
			follow_hero_direct(delta)