extends Node2D

@export var max_wpm_diff := 30.0
@export var overload_reduce := 20.0
@export var work_time: WorkTime

@export_category("Interview")
@export var min_documents := 2

@export_category("Crunch")
@export var max_bgm_pitch := 2.0
@export var max_bgm_pitch_time := 0.4
@export var crunch_start_spawn_time := 4.
@export var crunch_min_spawn_time := 0.4

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
@onready var pause: Pause = $CanvasLayer/Pause

@onready var bgm = $BGM

var is_gameover = false
var documents = []

func _set_environment():
	if GameManager.day <= 3 or GameManager.is_intern():
		animation_player.play("normal")
	elif not GameManager.is_management():
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
	
	if not GameManager.is_intern() or GameManager.is_crunch_mode():
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
		if GameManager.is_work_mode():
			var p = _get_difficulty_level()
			if p > 0.7:
				doc_spawner.add_hard()
			elif p > 0.4:
				doc_spawner.add_medium()
	)
		
	key_reader.pressed_key.connect(func(key, shift):
		if not documents.is_empty():
			documents[0].handle_key(key)
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not is_gameover:
		pause.grab_focus()

func _on_day_finished():
	if GameManager.is_work_mode():
		bgm.pitch_scale = GameManager.difficulty.bgm_speed
	else:
		bgm.pitch_scale = 1.0
	
	if GameManager.day > 1 and GameManager.is_work_mode():
		_start_game()
	else:
		_spawn_document(true)
		#animation_player.play("silent_bgm")
		#await animation_player.animation_finished
		animation_player.play("tutorial")

func _start_game():
	key_reader.process_mode = Node.PROCESS_MODE_ALWAYS
	work_time.start()
	overload_progress.start()
	animation_player.play("start_bgm")
	if not bgm.playing:
		bgm.play()
	
	_spawn()

func _process(_delta):
	var max_documents = 5.0
	var workload = documents.size() / max_documents
	overload_progress.multiplier = max(workload, 0.5)

func _finished(is_gameover = false):
	self.is_gameover = is_gameover
	
	if GameManager.is_work_mode():
		GameManager.finished_day(document_stack.total, work_time.get_overtime())
		distractions.slide_all_out()
		if is_gameover:
			gameover.fired()
		else:
			end.day_ended(document_stack.total, work_time.get_overtime())
	elif GameManager.is_interview_mode():
		GameManager.finished_interview(document_stack.total, work_time.timed_mode_seconds)
		end.interview_ended(document_stack.total)
	else:
		GameManager.finished_crunch(document_stack.total)
		end.crunch_ended(document_stack.total, work_time.hour)
			
func _spawn():
	if (work_time.ended and GameManager.is_work_mode()) or is_gameover:
		return
	
	_spawn_document()
	
	if GameManager.is_work_mode():
		if not GameManager.is_intern():
			var p = _get_difficulty_level()
			var t = lerp(GameManager.difficulty.max_documents, GameManager.difficulty.min_documents, p)

			spawn_timer.start(t)
	elif GameManager.is_interview_mode():
		if documents.size() < min_documents:
			_spawn()
	else:
		var t = _crunch_mode_spawn_time()
		spawn_timer.start(t)
		
		var pitch = remap(document_stack.total, 1.0, 80, 1.0, max_bgm_pitch)
		bgm.pitch_scale = snappedf(pitch, 0.25)
		print(t, " - ", pitch, " -> ", bgm.pitch_scale)

func _crunch_mode_spawn_time(doc_count: int = document_stack.total):
	var x = max(doc_count, 1)
	return max(crunch_start_spawn_time - (log(x) / log(10)) * 1.8, crunch_min_spawn_time)

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
		
		if not work_time.ended and GameManager.is_work_mode():
			distractions.maybe_show_distraction()

		if documents.size() > 0:
			documents[0].highlight()
			
			if GameManager.is_interview_mode() and documents.size() < min_documents:
				_spawn()
		elif work_time.ended and GameManager.is_work_mode():
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
