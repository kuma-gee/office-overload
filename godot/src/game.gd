extends Node2D

@export var max_increase := 0.1
@export var min_increase := 0.01
@export var base := 0.9782 # sqrt(max_increase + min_increase, 100)

@export var start_time := 2.0
@export var max_time := 1.0
@export var time_increase := 0.05

@export var overload_reduce := 20.0

@onready var doc_spawner = $DocSpawner
@onready var spawn_timer = $SpawnTimer
@onready var overload_progress = $CanvasLayer/HUD/MarginContainer/OverloadProgress
@onready var cleared_label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/Cleared
@onready var open_label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/Open

@onready var time_multiplier := 1.0 - time_increase
@onready var time := start_time

var documents = []
var cleared := 0
var overload := 0.0

func _ready():
	_spawn()
	overload_progress.value = 0.0
	_update_open()
	_update_cleared()

func _update_open():
	open_label.text = "Open: %s" % documents.size()

func _update_cleared():
	cleared_label.text = "Finished: %s" % cleared

func _process(delta):
	var diff_to_max = int(overload_progress.max_value - overload)
	var increase = pow(base, overload) - max_increase
	
	var max_documents = 10
	var workload = min(documents.size() / max_documents, 100)
	
	overload += clamp(increase, min_increase, max_increase) * max(workload, 0.3)
	if overload > 100:
		overload = 100
	
	overload_progress.value = overload

func _spawn():
	var doc = doc_spawner.spawn_document()
	doc.finished.connect(func():
		doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
		documents.erase(doc)
		if documents.size() > 0:
			documents[0].highlight()
		
		overload -= overload_reduce
		if overload < 0:
			overload = 0
		cleared += 1
		
		_update_open()
		_update_cleared()
	)
	
	if documents.is_empty():
		doc.highlight()
	
	documents.append(doc)
	_update_open()
	
	time = max(time * time_multiplier, max_time)
	spawn_timer.start(time)

func _on_spawn_timer_timeout():
	_spawn()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not documents.is_empty():
		var text = event.as_text()
		if text.length() != 1:
			return
		
		documents[0].handle_key(text)
