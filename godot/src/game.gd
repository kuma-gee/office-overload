extends Node2D

@export var start_time := 2.0
@export var max_time := 1.0
@export var time_increase := 0.05

@export var overload_reduce := 20.0

@onready var doc_spawner = $DocSpawner
@onready var spawn_timer = $SpawnTimer
@onready var overload_progress = $CanvasLayer/HUD/MarginContainer/OverloadProgress
@onready var cleared_label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/Cleared
@onready var open_label = $CanvasLayer/HUD/MarginContainer2/VBoxContainer/Open
@onready var overload_timer = $OverloadTimer
@onready var gameover = $CanvasLayer/Gameover
@onready var gameover_effect = $GameoverEffect

@onready var time_multiplier := 1.0 - time_increase
@onready var time := start_time

var documents = []
var cleared := 0
var is_gameover = false

func _ready():
	_spawn()
	gameover.hide()
	_update_open()
	_update_cleared()
	
	overload_progress.filled.connect(func(): overload_timer.start())
	
	#overload_timer.started.connect(func():
		#overload_progress.modulate = Color.RED
	#)
	#overload_timer.stopped.connect(func():
		#overload_progress.modulate = Color.WHITE
	#)
	overload_timer.timeout.connect(func():
		is_gameover = true
		spawn_timer.stop()
		gameover_effect.do_effect()
		gameover.show()
	)

func _update_open():
	open_label.text = "Open: %s" % documents.size()

func _update_cleared():
	cleared_label.text = "Finished: %s" % cleared

func _process(delta):
	var max_documents = 1 # TODO: revert to 10
	var workload = min(documents.size() / max_documents, 10)
	overload_progress.multiplier =  max(workload, 0.2)

func _spawn():
	var doc = doc_spawner.spawn_document()
	doc.finished.connect(func():
		doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
		documents.erase(doc)
		if documents.size() > 0:
			documents[0].highlight()
		
		overload_progress.reduce(overload_reduce)
		cleared += 1
		overload_timer.stop() 
		
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
	if is_gameover: return
	
	if event is InputEventKey and event.is_pressed() and not documents.is_empty():
		var text = event.as_text()
		if text.length() != 1:
			return
		
		documents[0].handle_key(text)


func _on_restart_pressed():
	get_tree().reload_current_scene()
