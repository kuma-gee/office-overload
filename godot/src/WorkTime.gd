class_name WorkTime
extends Label

signal started()
signal day_ended()
signal next_work_day()
signal time_changed()

@export var start_hour = 8
@export var end_hour = 18
@export var hour_in_seconds := 3

@export var timed_mode_seconds := 30

@export var timer: Timer
@export var day_end_sound: AudioStreamPlayer
@export var overtime_sound: AudioStreamPlayer

@onready var hour = start_hour : set = _set_hour

var stopped = false
var ended = false

func _ready():
	text = _hour_string(start_hour)
	_set_start_hour()

func _set_start_hour():
	match GameManager.current_mode:
		GameManager.Mode.Crunch:
			_set_hour(start_hour)
		GameManager.Mode.Interview:
			_set_hour(timed_mode_seconds / hour_in_seconds)
		GameManager.Mode.Work:
			_set_hour(start_hour)

func get_overtime():
	return max(hour - end_hour, 0)

func start():
	started.emit()
	_set_start_hour()
	_start_timer()
	stopped = false
	ended = false

func stop():
	stopped = true

func _start_timer():
	timer.start(hour_in_seconds)
	await timer.timeout
	
	if stopped or get_tree().paused: return

	if GameManager.is_interview_mode():
		self.hour -= 1
		
		if hour <= 0:
			next_work_day.emit()
	else:
		self.hour += 1
		
		if is_day_ended() and overtime_sound and GameManager.is_work_mode():
			overtime_sound.play()
		
	_start_timer()

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
		ended = true # only for work time mode
	elif actual_h == start_hour:
		started.emit()
		if overtime_sound:
			overtime_sound.play()

func _hour_string(hour: int):
	return "%02d" % hour
