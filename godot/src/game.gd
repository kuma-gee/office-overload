extends Node2D

@export var max_wpm_diff := 30.0
@export var overload_reduce := 20.0
@export var work_time: WorkTime

@onready var doc_spawner = $DocSpawner
@onready var spawn_timer = $SpawnTimer
@onready var document_stack = $DocumentStack
@onready var overload_timer = $OverloadTimer
@onready var keyboard = $Desk/Keyboard
@onready var clock = $Desk/Clock

@onready var overload_progress = $CanvasLayer/HUD/MarginContainer/OverloadProgress
@onready var progress_broken = $CanvasLayer/HUD/MarginContainer/ProgressBroken
@onready var animation_player = $AnimationPlayer
@onready var distractions = $CanvasLayer/Distractions

@onready var end = $CanvasLayer/End
@onready var gameover = $CanvasLayer/Gameover
@onready var key_reader = $KeyReader

@onready var bgm = $BGM

var is_gameover = false
var documents = []

func _set_environment():
	if GameManager.day <= 1 or GameManager.is_intern():
		animation_player.play("normal")
	elif GameManager.day <= 4:
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
		key_reader.process_mode = Node.PROCESS_MODE_DISABLED
	)
	
	if not GameManager.is_intern():
		overload_progress.filled.connect(func(): overload_timer.start())
		overload_timer.started.connect(func(): overload_progress.start_blink())
		overload_timer.stopped.connect(func(): overload_progress.stop_blink())
		overload_timer.timeout.connect(func():
			progress_broken.play()
			overload_progress.hide()
			_finished(true)
		)

		spawn_timer.timeout.connect(func(): _spawn())
	else:
		overload_progress.hide()

	work_time.next_work_day.connect(func(): _finished(true))
	work_time.day_ended.connect(func():
		if documents.is_empty():
			_finished()
	)

	document_stack.document_added.connect(func():
		var p = _get_difficulty_level()
		if p > 0.7:
			doc_spawner.add_hard()
		elif p > 0.4:
			doc_spawner.add_medium()
	)
		
	key_reader.pressed_key.connect(func(key, _s): if not documents.is_empty(): documents[0].handle_key(key))

func _on_day_finished():
	bgm.pitch_scale = GameManager.difficulty.bgm_speed
	
	if GameManager.day > 1:
		_start_game()
	else:
		_spawn_document(true)
		animation_player.play("tutorial")

func _start_game():
	key_reader.process_mode = Node.PROCESS_MODE_ALWAYS
	work_time.start()
	overload_progress.start()
	animation_player.play("start_bgm")
	_spawn()

func _process(_delta):
	var max_documents = 5.0
	var workload = documents.size() / max_documents
	overload_progress.multiplier = max(workload, 0.5)

func _finished(is_gameover = false):
	GameManager.finished_day(document_stack.total, work_time.get_overtime())
	distractions.slide_all_out()
	if is_gameover:
		gameover.fired()
	else:
		end.day_ended(document_stack.total, work_time.get_overtime())

func _spawn():
	if work_time.ended or is_gameover:
		return
	
	_spawn_document()
	
	if not GameManager.is_intern():
		var p = _get_difficulty_level()
		var t = lerp(GameManager.difficulty.max_documents, GameManager.difficulty.min_documents, p)

		spawn_timer.start(t)

func _get_difficulty_level():
	var start_wpm = GameManager.difficulty.average_wpm
	var end_wpm = GameManager.difficulty.average_wpm + max_wpm_diff
	var wpm_diff = GameManager.get_wpm() - start_wpm

	return clamp(wpm_diff / max_wpm_diff, 0.0, 1.0)

func _spawn_document(await_start = false):
	var doc = doc_spawner.spawn_document() as Document
	doc.started.connect(func(): GameManager.start_type())
	doc.finished.connect(func():
		GameManager.finish_type(doc.word, doc.mistakes)
		
		doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
		documents.erase(doc)
		
		overload_progress.reduce(overload_reduce)
		document_stack.add_document()
		overload_timer.stop()
		
		if not work_time.ended:
			distractions.maybe_show_distraction()

		if documents.size() > 0:
			documents[0].highlight()
		elif work_time.ended:
			_finished()
		else:
			if await_start:
				keyboard.frame = 0
				_start_game()
			else:
				spawn_timer.stop()
				_spawn()
	)

	if documents.is_empty():
		doc.highlight()
		
	if await_start:
		doc.show_tutorial()
		
	documents.append(doc)
