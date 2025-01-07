extends Sprite2D

@export var worktime: WorkTime
@export var point_light: PointLight2D
@export var canvas_modulate: CanvasModulate
@export var overload_progress: AutoProgressbar

@onready var clock_light_1 = $ClockLight1
@onready var clock_light_2 = $ClockLight2
@onready var clock_light_3 = $ClockLight3
@onready var clock_light_4 = $ClockLight4
@onready var lights := [clock_light_1, clock_light_2, clock_light_3, clock_light_4, point_light]

var light = 1.0:
	set(v):
		light = clamp(v, 0.2, 1)
		set_lights(light < 1)
		
		if canvas_modulate:
			canvas_modulate.color = Color(light, light, light, 1)
		
		if not overload_progress: return
		
		if light >= 0.3:
			overload_progress.brighten()
		else:
			overload_progress.darken()

func _ready():
	super._ready()
	if canvas_modulate:
		canvas_modulate.color = Color.WHITE
		canvas_modulate.show()
	set_lights(false)
	
	_work_frame()
	worktime.started.connect(func(): _work_frame())
	worktime.day_ended.connect(func(): _overtime_frame())
	worktime.time_changed.connect(func(time):
		if time >= 2 and time <= worktime.MORNING_TIME:
			light += 0.16
		elif time >= worktime.EVENING_TIME:
			light -= 0.1
	)

func _work_frame():
	frame = 0
	
func _overtime_frame():
	frame = 1

func set_lights(enabled: bool):
	for l in lights:
		if l:
			l.enabled = enabled
