extends Node2D

@export var overload_reduce := 20.0
@export var work_time: WorkTime

@onready var doc_spawner = $DocSpawner
@onready var spawn_timer = $SpawnTimer
@onready var document_stack = $DocumentStack
@onready var overload_timer = $OverloadTimer
@onready var keyboard = $Desk/Keyboard

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
@onready var key_reader = $KeyReader

@onready var bgm = $BGM

@export var difficulty: DifficultyResource

var is_gameover = false
var documents = []
var light = 1.0

func _set_environment():
	if GameManager.day <= 1:
		animation_player.play("normal")
	elif GameManager.day == 2:
		animation_player.play("messy")
	else:
		animation_player.play("littered")

func _ready():
	get_tree().paused = false
	_set_environment()
	
	GameManager.round_ended.connect(func():
		is_gameover = true
		overload_progress.stop()
		overload_timer.stop()
		work_time.stop()
		spawn_timer.stop()
		animation_player.play("stop_bgm")
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
		
	key_reader.pressed_key.connect(func(key, _s): if not documents.is_empty(): documents[0].handle_key(key))

	canvas_modulate.color = Color.WHITE
	canvas_modulate.show()
	_set_lights(false)

func _set_lights(enabled: bool):
	for l in lights:
		l.enabled = enabled

func _on_day_finished():
	bgm.stream = difficulty.bgm
	
	if GameManager.day > 1:
		_start_game()
	else:
		_spawn_document(true)
		animation_player.play("tutorial")

func _start_game():
	work_time.start()
	overload_progress.start()
	animation_player.play("start_bgm")
	_spawn()
	
func get_finished():
	return document_stack.total

func get_uncompleted():
	return documents.size()

func is_end_of_day():
	return work_time.ended

func _process(_delta):
	var max_documents = 5.0
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
	
	_spawn_document()
	
	var wpm_diff = 20
	var wpm = GameManager.get_wpm()
	
	# TODO: change based on wpm
	var t = difficulty.max_documents
	spawn_timer.start(t)

func _spawn_document(show_tutorial = false):
	var doc = doc_spawner.spawn_document() as Document
	doc.started.connect(func(): GameManager.start_type())
	doc.finished.connect(func():
		GameManager.finish_type(doc.word)
		
		doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
		documents.erase(doc)
		
		if documents.size() > 0:
			documents[0].highlight()
		elif not show_tutorial:
			spawn_timer.stop()
			_spawn()
		
		overload_progress.reduce(overload_reduce)
		document_stack.add_document()
		overload_timer.stop() 
		
		if get_finished() == 20:
			doc_spawner.add_hard()
		elif get_finished() == 10:
			doc_spawner.add_medium()
			
		if is_end_of_day() and documents.is_empty():
			_finished()
			
		if show_tutorial:
			keyboard.frame = 0
			_start_game()
	)

	if documents.is_empty():
		doc.highlight()
		
	if show_tutorial:
		doc.show_tutorial()
		
	documents.append(doc)
