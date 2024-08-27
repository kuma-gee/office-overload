class_name WorkTime
extends Label

signal started()
signal day_ended()
signal next_work_day()
signal time_changed()

@export var start_hour = 8
@export var end_hour = 16
@export var hour_in_seconds := 5

@export var timed_mode_seconds := 30

@export var timer: Timer
@export var day_end_sound: AudioStreamPlayer
@export var overtime_sound: AudioStreamPlayer

@onready var hour = start_hour : set = _set_hour

var stopped = false
var ended = false
var days := 0

func _ready():
	_set_start_hour()
	
func _set_start_hour():
	match GameManager.current_mode:
		GameManager.Mode.Crunch:
			_set_hour(0)
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

	if GameManager.current_mode == GameManager.Mode.Interview:
		self.hour -= 1
		
		if hour == 0:
			next_work_day.emit()
	else:
		self.hour += 1
		
		if hour == end_hour:
			day_ended.emit()
			if day_end_sound:
				day_end_sound.play()
			ended = true
		
		if hour > end_hour:
			if overtime_sound:
				overtime_sound.play()
		
	_start_timer()

func _set_hour(h: int):
	hour = h
	text = ""
	
	if hour < 24:
		text += _hour_string(h)
	else:
		var actual_h = hour - 24
		if actual_h >= start_hour:
			if GameManager.current_mode == GameManager.Mode.Work:
				next_work_day.emit()
			days += 1
		text += _hour_string(actual_h)
	
	time_changed.emit(hour)

func _hour_string(hour: int):
	return "%s" % [hour if hour > 9 else "0" + str(hour)]
