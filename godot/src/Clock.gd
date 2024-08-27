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

var light = 1.0

func _ready():
	canvas_modulate.color = Color.WHITE
	canvas_modulate.show()
	set_lights(false)
	
	_work_frame()
	worktime.started.connect(func(): _work_frame())
	worktime.day_ended.connect(func(): _overtime_frame())
	worktime.time_changed.connect(func(time):
		if not worktime.ended:
			return
		
		if time > 24 + 2:
			light = min(light + 0.16, 1)
		else:
			light = max(light - 0.1, 0.2)
		
		canvas_modulate.color = Color(light, light, light, 1)
		
		if light >= 1:
			set_lights(false)
			
		if light >= 0.3:
			overload_progress.brighten()
		else:
			overload_progress.darken()
	)

func _work_frame():
	frame = 0
	
func _overtime_frame():
	frame = 1
	set_lights(true)

func set_lights(enabled: bool):
	for l in lights:
		l.enabled = enabled
