extends TextureProgressBar

signal filled()

# Exponential increase
@export var max_increase := 0.1
@export var min_increase := 0.01
@export var base := 0.9782 # sqrt(max_increase + min_increase, 100)

@export var blink_start_time := 0.5
@export var blink_timer_reference: Timer

var multiplier := 1.0
var running := false

var base_blink_time := -1.0

func _ready():
	value = 0.0
	pivot_offset = size / 2

func start():
	running = true

func _process(delta):
	if not running: return
	
	var was_full = is_full()
	var increase = pow(base, value) - max_increase
	value += clamp(increase, min_increase, max_increase) * multiplier
	if value > max_value:
		value = max_value

	if not was_full and is_full():
		filled.emit()


func is_full():
	return value >= max_value

func reduce(amount: float):
	value -= amount
	if value < 0:
		value = 0

func start_blink():
	base_blink_time = blink_start_time
	_blink()

func stop_blink():
	base_blink_time = -1
	material.set_shader_parameter("enable", false)

func _blink(duration := 0.2):
	material.set_shader_parameter("enable", true)
	await get_tree().create_timer(duration).timeout
	material.set_shader_parameter("enable", false)
	
	var next_time_multiplier = (blink_timer_reference.time_left / blink_timer_reference.wait_time)
	next_time_multiplier *= next_time_multiplier
	var next_time = max(base_blink_time * next_time_multiplier, 0.1)
	get_tree().create_timer(next_time).timeout.connect(func():
		if base_blink_time > 0:
			_blink()
	)
