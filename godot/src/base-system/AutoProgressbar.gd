extends TextureProgressBar

signal filled()

# Exponential increase
@export var max_increase := 0.1
@export var min_increase := 0.01
@export var base := 0.9782 # sqrt(max_increase + min_increase, 100)

var multiplier := 1.0

func _ready():
	value = 0.0

func _process(delta):
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

