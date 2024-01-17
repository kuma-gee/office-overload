extends Sprite2D

@export var worktime: WorkTime

func _ready():
	_work_frame()
	worktime.started.connect(func(): _work_frame())
	worktime.day_ended.connect(func(): _overtime_frame())

func _work_frame():
	frame = 0
	
func _overtime_frame():
	frame = 1
