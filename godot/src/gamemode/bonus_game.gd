class_name BonusGame
extends Node2D

@export var min_documents := 2
@export var progress_bar: ConstantProgressBar
@export var day: Day
@export var work_time: WorkTime

@onready var doc_spawner: DocSpawner = $DocSpawner
@onready var meeting_spawner: DocSpawner = $MeetingSpawner
@onready var key_reader: KeyReader = $KeyReader
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_gameover := false
var documents := []
var type_time := []

func _ready() -> void:
	if GameManager.is_morning_mode():
		work_time.start_hour = 6
		work_time.end_hour = 8
		work_time.hour_in_seconds = 5
	elif GameManager.is_meeting_mode():
		work_time.start_hour = 8
		work_time.end_hour = 12
		work_time.hour_in_seconds = 5
		animation_player.play("meeting")
	elif GameManager.is_afterwork_mode():
		work_time.start_hour = 18
		work_time.end_hour = 24
		work_time.hour_in_seconds = 5
		animation_player.play("bar")
	
	day.finished.connect(func(): start_game())
	work_time.day_ended.connect(func(): _finished())
	
	key_reader.pressed_key.connect(func(key, shift):
		if not documents.is_empty():
			documents[0].handle_key(key)
	)
	
func start_game():
	if GameManager.is_afterwork_mode():
		progress_bar.start()
	
	work_time.start()
	_spawn()

func _spawn():
	if work_time.is_day_ended() or is_gameover:
		return
	
	_spawn_document()
	if documents.size() < min_documents:
		_spawn()


func _spawn_document():
	var doc = null
	if GameManager.is_afterwork_mode():
		doc = doc_spawner.spawn_document(0.0) as Document
		_add_document(doc)
	elif GameManager.is_meeting_mode():
		doc = meeting_spawner.spawn_document(0.0) as Document
		_add_meeting_document(doc)

	if not doc: return
	if documents.is_empty():
		doc.highlight()
	
	documents.append(doc)

func _add_document(doc: Document):
	doc.typed.connect(func(): progress_bar.typed())
	doc.finished.connect(func():
		doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
		_on_document_finished(doc)
	)

func _add_meeting_document(doc: Document):
	doc.finished.connect(func():
		doc.return_to()
		_on_document_finished(doc)
	)

func _on_document_finished(doc: Document):
	documents.erase(doc)
	if documents.size() > 0:
		documents[0].highlight()
		
		if documents.size() < min_documents:
			_spawn()
	else:
		_spawn()
	

func _finished():
	is_gameover = true
	progress_bar.stop()
	work_time.stop()

	progress_bar.calculate_score()
