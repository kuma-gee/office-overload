extends Node2D

@export var start_time := 2.0
@export var max_time := 1.0
@export var time_increase := 0.03

@export var overload_reduce := 20.0

@onready var doc_spawner = $DocSpawner
@onready var spawn_timer = $SpawnTimer
@onready var overload_progress = $CanvasLayer/HUD/MarginContainer/OverloadProgress
@onready var cleared_label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/Cleared
@onready var open_label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/Open
@onready var overload_timer = $OverloadTimer
@onready var end = $CanvasLayer/End
@onready var gameover = $CanvasLayer/Gameover
@onready var work_time = $CanvasLayer/HUD/MarginContainer3/WorkTime
@onready var document_stack = $DocumentStack

@onready var time_multiplier := 1.0 - time_increase
@onready var time := start_time

var documents = []
var is_gameover = false
var end_of_day = false

func get_finished():
	return document_stack.total

func get_uncompleted():
	return documents.size()

func _ready():
	_update_open()
	_update_cleared()
	
	overload_progress.filled.connect(func(): overload_timer.start())
	overload_timer.timeout.connect(func():
		is_gameover = true
		spawn_timer.stop()
		gameover.fired(get_finished(), get_uncompleted())
	)

	work_time.day_ended.connect(func(): end_of_day = true)
	work_time.next_work_day.connect(func(): gameover.fired_next_day(get_uncompleted()))
	spawn_timer.timeout.connect(func(): _spawn())

func _on_day_finished():
	_start_game()

func _start_game():
	work_time.start()
	overload_progress.start()
	_spawn()

func _update_open():
	open_label.text = "Open: %s" % get_uncompleted()

func _update_cleared():
	cleared_label.text = "Finished: %s" % get_finished()

func _process(delta):
	var max_documents = 10
	var workload = min(documents.size() / max_documents, 10)
	overload_progress.multiplier =  max(workload, 0.5)

func _spawn():
	if end_of_day: return
	
	var doc = doc_spawner.spawn_document()
	doc.finished.connect(func():
		doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
		documents.erase(doc)
		if documents.size() > 0:
			documents[0].highlight()
		
		overload_progress.reduce(overload_reduce)
		document_stack.add_document()
		overload_timer.stop() 
		
		_update_open()
		_update_cleared()
		
		if get_finished() == 30:
			doc_spawner.add_hard()
		elif get_finished() == 15:
			doc_spawner.add_medium()
			
		if end_of_day and documents.is_empty():
			end.day_ended(get_finished(), work_time.get_overtime())
	)
	
	if documents.is_empty():
		doc.highlight()
	
	documents.append(doc)
	_update_open()
	
	time = max(time * time_multiplier, max_time)
	if documents.size() > 20:
		time = start_time
	spawn_timer.start(time)

func _unhandled_input(event: InputEvent):
	if is_gameover: return
	
	if event is InputEventKey and event.is_pressed() and not documents.is_empty():
		var text = event.as_text()
		if text.length() != 1:
			return
		
		documents[0].handle_key(text)
