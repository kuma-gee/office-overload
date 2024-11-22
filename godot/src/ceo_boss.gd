extends Node2D

@export var min_documents := 2
@export var boss_process_speed := 3.0
@export var work_time: WorkTime
@export var player_doc_label: Label
@export var boss_doc_label: Label

@export_category("Boss")
@export var boss_attack_count := 3
@export var boss_attack_timer: Timer

@onready var key_reader: KeyReader = $KeyReader
@onready var document_stack: DocumentStack = $DocumentStack
@onready var doc_spawner: DocSpawner = $DocSpawner
@onready var day: Day = $CanvasLayer/Day
@onready var start_stack: DocumentStack = $StartStack
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var end: Control = $CanvasLayer/End
@onready var pause: Pause = $CanvasLayer/Pause
@onready var camera_shake: CameraShake = $CameraShake

var documents := []
var is_gameover := false
var attacking := false

var boss_documents := 0:
	set(v):
		boss_documents = v
		boss_doc_label.text = "%s" % boss_documents
var boss_processing := 0.0

func _ready() -> void:
	day.finished.connect(func(): _start_game())
	key_reader.pressed_key.connect(func(key, shift):
		if not documents.is_empty():
			if not documents[0].handle_key(key):
				document_stack.remove_combo()
	)
	key_reader.pressed_cancel.connect(func(shift):
		if not is_gameover:
			pause.grab_focus()
	)
	
	work_time.day_ended.connect(func(): _game_ended())
	start_stack.document_emptied.connect(func(): _game_ended())
	boss_attack_timer.timeout.connect(_boss_attack)

func _boss_attack():
	# TODO: indicate attack

	attacking = true
	camera_shake.shake()
	await get_tree().create_timer(0.5).timeout
	camera_shake.shake()
	await get_tree().create_timer(0.5).timeout

	var type = doc_spawner.get_invalid_type()
	var count = randi_range(boss_attack_count-1, boss_attack_count+1)
	for doc in doc_spawner.spawn_invalid_documents(type, count):
		_add_document(doc)
	
	boss_attack_timer.start()
	attacking = false
	
func _game_ended():
	var data = {
		"total": document_stack.total,
		# "combo": document_stack.combo_count,
		"wrong": document_stack.wrong_tasks,
	}
	GameManager.calculate_performance(data)

	var boss_data = {
		"total": boss_documents,
		# "combo": randi_range(0, boss_documents * 0.3),
		"wrong": randi_range(boss_documents * 0.1, boss_documents * 0.3),
	}
	GameManager.calculate_performance(boss_data)

	end.open(data, boss_data)

	# TODO:
	# if data["points"] > boss_data["points"]:
	# 	GameManager.unlock_mode(GameManager.Mode.Multiplayer)

func _start_game():
	work_time.start()
	animation_player.play("start")
	boss_attack_timer.start()
	_spawn()

func _spawn():
	if start_stack.has_documents():
		_spawn_document()
	else:
		_finished()

func _spawn_document():
	if boss_attack_timer.is_stopped() and start_stack.total >= 5 and not attacking:
		_boss_attack()
	else:
		start_stack.remove_document()
		
		var invalid_chance = GameManager.difficulty.invalid_word_chance
		var doc = doc_spawner.spawn_document(invalid_chance) as Document
		_add_document(doc)

func _add_document(doc: Document):
	doc.started.connect(func(): GameManager.start_type())
	doc.finished.connect(func():
		GameManager.finish_type(doc.word, doc.mistakes)
		player_doc_label.text = "%s" % document_stack.total
		
		if doc.is_discarded:
			doc.move_to(doc.global_position + Vector2.DOWN * 200)
		else:
			doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))

		document_stack.add_document(doc.mistakes > 0, doc_spawner.is_invalid_word(doc.word), doc.is_discarded)
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
