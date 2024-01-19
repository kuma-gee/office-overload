extends Node2D

@export var start_time := 2.0
@export var min_time := 1.0
@export var time_increase := 0.02

@export var overload_reduce := 20.0

@export var work_time: WorkTime

@export var normal: AudioStream
@export var fast: AudioStream
@export var faster: AudioStream
@export var fastest: AudioStream

@onready var doc_spawner = $DocSpawner
@onready var spawn_timer = $SpawnTimer
@onready var document_stack = $DocumentStack
@onready var overload_timer = $OverloadTimer

@onready var overload_progress = $CanvasLayer/HUD/MarginContainer/OverloadProgress
@onready var progress_broken = $CanvasLayer/HUD/MarginContainer/ProgressBroken
@onready var animation_player = $AnimationPlayer

@onready var canvas_modulate = $CanvasModulate
@onready var clock_light_1 = $Desk/Clock/ClockLight1
@onready var clock_light_2 = $Desk/Clock/ClockLight2
@onready var clock_light_3 = $Desk/Clock/ClockLight3
@onready var clock_light_4 = $Desk/Clock/ClockLight4
@onready var point_light_2d = $PointLight2D
@onready var lights = [clock_light_1, clock_light_2, clock_light_3, clock_light_4, point_light_2d]

@onready var end = $CanvasLayer/End
@onready var gameover = $CanvasLayer/Gameover

@onready var bgm = $BGM
@onready var time: float = _get_start_time()

var is_gameover = false
var documents = []
var light = 1.0

func _get_start_time():
	var day_percent = (GameManager.day - 1.0) / 2.0 # Day 3 will start with lowest time
	var time_diff = start_time - min_time
	var actual_diff = time_diff * day_percent
	
	# make it more challenging
	if GameManager.day > 3:
		min_time = 0.75
	
	return start_time - actual_diff

func _ready():
	if GameManager.day <= 1:
		animation_player.play("normal")
	elif GameManager.day == 2:
		animation_player.play("messy")
	else:
		animation_player.play("littered")
	
	GameManager.round_ended.connect(func():
		is_gameover = true
		overload_progress.stop()
		overload_timer.stop()
		work_time.stop()
		spawn_timer.stop()
		bgm.stop()
	)
	
	overload_progress.filled.connect(func(): overload_timer.start())
	overload_timer.started.connect(func(): overload_progress.start_blink())
	overload_timer.stopped.connect(func(): overload_progress.stop_blink())
	overload_timer.timeout.connect(func():
		progress_broken.play()
		overload_progress.hide()
		_lost()
	)
	work_time.next_work_day.connect(func(): _lost(true))
	work_time.day_ended.connect(func():
		if documents.is_empty():
			_finished()
		
		_set_lights(true)
	)
	work_time.time_changed.connect(func(time):
		if not is_end_of_day():
			return
		
		if time > 24 + 2:
			light = min(light + 0.16, 1)
		else:
			light = max(light - 0.1, 0.2)
		
		canvas_modulate.color = Color(light, light, light, 1)
		
		if light >= 1:
			_set_lights(false)
			
		if light >= 0.3:
			overload_progress.brighten()
		else:
			overload_progress.darken()
	)
	spawn_timer.timeout.connect(func(): _spawn())

	canvas_modulate.color = Color.WHITE
	canvas_modulate.show()
	_set_lights(false)

func _set_lights(enabled: bool):
	for l in lights:
		l.enabled = enabled

func _on_day_finished():
	_start_game()
	
func get_finished():
	return document_stack.total

func get_uncompleted():
	return documents.size()

func is_end_of_day():
	return work_time.ended

func _start_game():
	work_time.start()
	overload_progress.start()
	_set_pitch()
	bgm.do_play()
	_spawn()

func _process(delta):
	var max_documents = 5
	var workload = documents.size() / max_documents
	overload_progress.multiplier =  max(workload, 0.5)

func _finished():
	_save_progress()
	end.day_ended(get_finished(), work_time.get_overtime())

func _lost(end_of_day = false):
	_save_progress()
	gameover.fired(get_finished(), get_uncompleted(), end_of_day)

func _save_progress():
	GameManager.finished_day(get_finished(), work_time.get_overtime())

func _spawn():
	if is_end_of_day() or is_gameover:
		return
	
	var doc = doc_spawner.spawn_document()
	doc.finished.connect(func():
		doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
		documents.erase(doc)
		
		if documents.size() > 0:
			documents[0].highlight()
		
		overload_progress.reduce(overload_reduce)
		document_stack.add_document()
		overload_timer.stop() 
		
		if get_finished() == 30:
			doc_spawner.add_hard()
		elif get_finished() == 15:
			doc_spawner.add_medium()
			
		if is_end_of_day() and documents.is_empty():
			_finished()
	)
	
	if documents.is_empty():
		doc.highlight()
	
	documents.append(doc)
	
	time = max(time * (1.0 - time_increase * GameManager.day), min_time)
	_set_pitch()
	
	# might be too easy
	#if documents.size() > 20:
		#time = start_time * 0.75
		
	spawn_timer.start(time)

func _set_pitch():
	if time <= 1.0:
		bgm.next_stream = fastest
	elif time <= 1.2:
		bgm.next_stream = faster
	elif time <= 1.5:
		bgm.next_stream = fast
	else:
		bgm.next_stream = normal
	
	if documents.size() > 20:
		bgm.next_stream = fastest


func _unhandled_input(event: InputEvent):
	if not is_gameover and event is InputEventKey and event.is_pressed() and not documents.is_empty():
		var text = event.as_text()
		if text.length() != 1:
			return
		
		documents[0].handle_key(text)
