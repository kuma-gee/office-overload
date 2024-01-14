extends Label

signal started()
signal day_ended()
signal next_work_day()

@export var start_hour = 8
@export var end_hour = 17;
@export var hour_in_seconds := 10

@onready var hour = start_hour : set = _set_hour

var timer: SceneTreeTimer
var stopped = false
var ended = false

func _ready():
	_set_hour(start_hour)

func get_overtime():
	return hour - end_hour

func start():
	started.emit()
	self.hour = start_hour
	_start_timer()
	stopped = false
	ended = false

func stop():
	timer.stop()
	stopped = true

func _start_timer():
	timer = get_tree().create_timer(hour_in_seconds)
	timer.timeout.connect(func():
		if stopped or get_tree().paused: return
		
		self.hour += 1
		if hour >= end_hour:
			day_ended.emit()
			ended = true
		
		_start_timer()
	)

func _set_hour(h: int):
	hour = h
	
	text = ""
	if ended:
		text = "(+ %s) " % _hour_string(get_overtime())
	
	if hour <= 24:
		text += _hour_string(h)
	else:
		var actual_h = hour - 24
		if actual_h >= start_hour:
			next_work_day.emit()
		text = _hour_string(actual_h)

func _hour_string(hour: int):
	return "%s:00" % [hour if hour > 9 else "0" + str(hour)]
