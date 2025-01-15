class_name WorkTime
extends Label

signal started()
signal day_ended()
signal next_work_day()
signal time_changed()

const EVENING_TIME = 18
const MORNING_TIME = 8

@export var start_hour = 8:
	set(v):
		start_hour = v
		text = _hour_string(v)
@export var end_hour = 18
@export var hour_in_seconds := 3

@export var timer: Timer
@export var day_end_sound: AudioStreamPlayer
@export var overtime_sound: AudioStreamPlayer

@onready var hour = start_hour : set = _set_hour

var hours_passed := 0
var stopped = true

func _ready():
	self.start_hour = start_hour
	_set_start_hour()
	
	timer.timeout.connect(func():
		if stopped or get_tree().paused: return
		
		self.hour += 1
		hours_passed += 1

		if is_day_ended() and overtime_sound and GameManager.is_work_mode():
			overtime_sound.play()
	)

func _set_start_hour():
	_set_hour(start_hour)

func get_overtime():
	return max(hour - end_hour, 0)

func get_worked_hours():
	return hour - start_hour

func start():
	hour = start_hour
	started.emit()
	_set_start_hour()
	_start_timer()
	stopped = false

func stop():
	stopped = true
	timer.stop()

func _start_timer():
	timer.start(hour_in_seconds)
	#await timer.timeout
	#
	#if stopped or get_tree().paused: return
#
	#self.hour += 1
	#
	##if is_day_ended() and overtime_sound and GameManager.is_work_mode():
		##overtime_sound.play()
		#
	#_start_timer()

func is_day_ended():
	var h = hour % 24
	return h >= end_hour and h <= 24 or h >= 0 and h < start_hour

func _set_hour(h: int):
	if hour == h: return
	
	hour = h
	text = ""
	
	var actual_h = hour % 24
	if actual_h >= start_hour and hour > 24 and GameManager.is_work_mode():
		next_work_day.emit()
	
	text += _hour_string(actual_h)
	
	time_changed.emit(actual_h)
	
	if actual_h == end_hour:
		day_ended.emit()
		if day_end_sound:
			day_end_sound.play()
	elif actual_h == start_hour:
		started.emit()
		if overtime_sound and GameManager.is_work_mode():
			overtime_sound.play()

func _hour_string(hour: int):
	return "%02d" % hour
