class_name ConstantProgressBar
extends TextureProgressBar

@export var drunk_overlay: Control
@export var max_speed := 10.0
@export var drunk_blur_max := 500.0
@export var drunk_speed_max := 100.0
@export var drunk_process_speed := 0.01

var target_wpm := 0.0
var seconds_for_one_char := 0.0
var running := false
var time := 0.0
var time_diffs := []

var drunk_amount := 0.0

func _ready():
	value = 0.0
	target_wpm = 50 #GameManager.average_wpm * 0.5 # 5 char / 60s
	
	var total_chars_per_minute = target_wpm * 5
	var total_chars_per_second = total_chars_per_minute / 60
	seconds_for_one_char = 1 / total_chars_per_second
	
	set_drunk_speed(0.0)
	set_drunk_blur(0.0)

func start():
	running = true

func stop():
	running = false

func typed():
	time += seconds_for_one_char * 2
	time_diffs.append(time)
	
	if time > 0:
		drunk_amount += time
		print(drunk_amount)
	

func _process(delta):
	if not running: return
	time -= delta
	value = time
	
	if drunk_amount > 0:
		drunk_amount -= drunk_process_speed
	
	set_drunk_speed(drunk_amount / drunk_speed_max)
	set_drunk_blur(drunk_amount)

func calculate_score():
	var avg = calculate_average()
	var diff = abs(seconds_for_one_char - avg)

	print("Score: ", avg, ", ", diff)
	return 0.0

func calculate_average():
	var total = time_diffs.reduce(func(acc, x): return acc + x, 0.0)
	return total / time_diffs.size()

func set_drunk_speed(speed := 0.0):
	var mat = drunk_overlay.material as ShaderMaterial
	var s = clamp(speed, 0, max_speed)
	mat.set_shader_parameter("speed", Vector2(s, s))
	
	if s == 0:
		mat.set_shader_parameter("amplitutde", Vector2(0, 0))
	else:
		var x = remap(s, 0, max_speed, 0, 0.01)
		mat.set_shader_parameter("amplitutde", Vector2(x, x))
	
func set_drunk_blur(blur := 0.0):
	var mat = drunk_overlay.material as ShaderMaterial
	var b = clamp(blur, 0.0, drunk_blur_max)
	var x = remap(b, 0.0, drunk_blur_max, 1.0, 0.98)
	mat.set_shader_parameter("blur", x)
