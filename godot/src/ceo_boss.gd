extends Node2D

@export var min_documents := 1
@export var boss_process_speed := 1.0
@export var work_time: WorkTime

@onready var key_reader: KeyReader = $KeyReader
@onready var document_stack: DocumentStack = $DocumentStack
@onready var doc_spawner: Marker2D = $DocSpawner
@onready var day: Day = $CanvasLayer/Day
@onready var start_stack: DocumentStack = $StartStack
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var end: Control = $CanvasLayer/End

var documents := []
var is_gameover := false

var boss_documents := 0
var boss_processing := 0.0

func _ready() -> void:
	day.finished.connect(func(): _start_game())
	key_reader.pressed_key.connect(func(key, shift):
		if not documents.is_empty():
			if not documents[0].handle_key(key):
				document_stack.remove_combo()
	)
	
	start_stack.document_emptied.connect(func(): _game_ended())
	work_time.day_ended.connect(func(): _game_ended())
	
func _game_ended():
	var data = {
		"total": document_stack.total,
		"combo": document_stack.combo_count,
		"wrong": document_stack.wrong_tasks,
	}
	var boss_data = {
		"total": boss_documents,
		"combo": randi_range(0, boss_documents * 0.5),
		"wrong": randi_range(boss_documents * 0.1, boss_documents * 0.3),
	}
	end.open(data, boss_data)

func _start_game():
	work_time.start()
	animation_player.play("start")
	_spawn()

func _spawn():
	if start_stack.has_documents():
		_spawn_document()
	else:
		_finished()

func _spawn_document(await_start = false):
	start_stack.remove_document()
	
	var invalid_chance = GameManager.difficulty.invalid_word_chance
	var doc = doc_spawner.spawn_document(invalid_chance) as Document
	doc.started.connect(func(): GameManager.start_type())
	doc.finished.connect(func():
		GameManager.finish_type(doc.word, doc.mistakes)
		
		if doc.is_discarded():
			doc.move_to(doc.global_position + Vector2.DOWN * 200)
		else:
			doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))

		document_stack.add_document(doc.mistakes > 0, doc_spawner.is_invalid_word(doc.word), doc.is_discarded())
		documents.erase(doc)

		if documents.size() > 0:
			documents[0].highlight()
			
			if documents.size() < min_documents:
				_spawn()
		elif work_time.ended:
			_finished()
		else:
			_spawn()
	)

	if documents.is_empty():
		doc.highlight()
		
	if await_start:
		doc.show_tutorial()
		
	documents.append(doc)

func _process(delta: float) -> void:
	if is_gameover: return
	
	boss_processing += delta
	if boss_processing >= boss_process_speed and start_stack.has_documents():
		boss_processing = 0
		boss_documents += 1
		start_stack.remove_document()

func _finished():
	is_gameover = true
	
	#if GameManager.is_work_mode():
		#var data = {
			#"total": document_stack.total,
			#"perfect": document_stack.perfect_tasks,
			#"overtime": work_time.get_overtime(),
			#"distractions": distractions.missed,
			#"wrong": document_stack.wrong_tasks,
		#}
		#GameManager.finished_day(data)
		#distractions.slide_all_out()
		#if is_gameover:
			#gameover.fired()
		#else:
			#end.day_ended(data)
			

func get_label():
	if documents.is_empty(): return null
	return documents[0].get_label()
