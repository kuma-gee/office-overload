class_name Game
extends Node2D

@export var overload_reduce := 20.0
@export var work_time: WorkTime
@export var max_document_count := 15 # slower documents at this point
@export var person_container: Haika

@export_category("Boss")
@export var min_documents := 2
@export var boss_process_speed := 3.0
@export var player_doc_label: Label
@export var boss_doc_label: Label
@export var boss_attack_count := 3
@export var boss_attack_timer: Timer

#@export_category("Interview")
#@export var min_documents := 2

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
@onready var shift_overlay: ShiftOverlay = $ShiftOverlay
@onready var start_stack: DocumentStack = $StartStack

@onready var bgm = $BGM
@onready var end = $CanvasLayer/End
@onready var gameover = $CanvasLayer/Gameover
@onready var key_reader = $KeyReader
@onready var pause: Pause = $CanvasLayer/Pause

@onready var camera_shake: CameraShake = $CameraShake
@onready var frame_freeze: FrameFreeze = $FrameFreeze

var is_gameover = false:
	set(v):
		is_gameover = v
		person_container.is_gameover = v

var documents = []
var attacking := false

var boss_documents := 0:
	set(v):
		boss_documents = v
		boss_doc_label.text = "%s" % boss_documents
var boss_processing := 0.0

func _set_environment():
	#if GameManager.day <= 3 or GameManager.is_intern():
	animation_player.play("normal")
	#elif not GameManager.is_manager():
		#animation_player.play("messy")
	#else:
		#animation_player.play("littered")

func _ready():
	randomize()
	get_tree().paused = false
	_set_environment()
	
	overload_progress.game = self
	
	GameManager.round_ended.connect(func():
		is_gameover = true
		overload_progress.stop()
		overload_timer.stop()
		work_time.stop()
		spawn_timer.stop()
		animation_player.play("stop_bgm")
		key_reader.process_mode = Node.PROCESS_MODE_DISABLED
	)
	
	if GameManager.is_ceo():
		start_stack.document_emptied.connect(func(): _finished())
		animation_player.play("ceo")
		work_time.hour_in_seconds = 10
	
	if not GameManager.is_intern() or GameManager.is_crunch_mode():
		overload_progress.filled.connect(func(): overload_timer.start())
		overload_timer.started.connect(func(): overload_progress.start_blink())
		overload_timer.stopped.connect(func(): overload_progress.stop_blink())
		overload_timer.timeout.connect(func():
			progress_broken.play()
			overload_progress.hide()
			frame_freeze.freeze()
			camera_shake.shake()
			_finished(true)
		)

		if not GameManager.is_ceo():
			spawn_timer.timeout.connect(func(): _spawn())
	else:
		overload_progress.hide()

	work_time.next_work_day.connect(func(): _finished(true))
	work_time.day_ended.connect(func():
		if documents.is_empty() or GameManager.is_intern():
			_finished()
	)
	
	key_reader.pressed_key.connect(func(key, shift):
		if not documents.is_empty():
			if documents[0].handle_key(key):
				document_stack.add_combo()
			else:
				document_stack.add_mistake()
	)
	key_reader.pressed_cancel.connect(func(shift):
		if not is_gameover:
			pause.grab_focus()
	)

func _on_day_finished():
	if GameManager.is_work_mode():
		bgm.pitch_scale = GameManager.difficulty.bgm_speed
	else:
		bgm.pitch_scale = 1.0
	
	if GameManager.day >= 1 and GameManager.is_work_mode():
		_start_game()
	else:
		_spawn_document(true)
		animation_player.play("tutorial")

func _start_game():
	key_reader.process_mode = Node.PROCESS_MODE_ALWAYS
	work_time.start()
	overload_progress.start()
	animation_player.play("start_bgm")
	if not bgm.playing:
		bgm.play()
	
	if GameManager.is_ceo():
		boss_attack_timer.start()
	
	_spawn()
	
func _finished(is_gameover = false):
	self.is_gameover = is_gameover
	
	if GameManager.is_work_mode():
		distractions.slide_all_out()
		
		if GameManager.is_ceo():
			_ceo_game_ended()
		else:
			var data = {
				"total": document_stack.total_points,
				"tasks": document_stack.tasks,
				"combo": document_stack.highest_streak,
				"wrong": document_stack.wrong_tasks,
				"overtime": work_time.get_overtime(),
			}
			GameManager.finished_day(data)
			if is_gameover:
				gameover.fired()
			else:
				end.day_ended(data)
			
	elif GameManager.is_interview_mode():
		GameManager.finished_interview(document_stack.actual_document_count, work_time.timed_mode_seconds)
		end.interview_ended(document_stack.total)
	else:
		GameManager.finished_crunch(document_stack.actual_document_count)
		end.crunch_ended(document_stack.total, work_time.hour)
			
func _spawn():
	if (work_time.is_day_ended() and GameManager.is_work_mode()) or is_gameover:
		return
	
	_spawn_document()
	
	if GameManager.is_work_mode():
		if not GameManager.is_intern():
			#var count = pow(2, 1 / documents.size())
			#var p = count / float(pow(2, max_document_count))
			#var t = lerp(GameManager.difficulty.max_documents, GameManager.difficulty.min_documents, p)
			
			var t = max(pow(GameManager.difficulty.max_documents, documents.size() / float(max_document_count)), GameManager.difficulty.min_documents)
			spawn_timer.start(t)
	elif GameManager.is_interview_mode():
		if documents.size() < min_documents:
			_spawn()
	else:
		var t = _crunch_mode_spawn_time()
		spawn_timer.start(t)
		
		var pitch = remap(document_stack.actual_document_count, 1.0, 80, 1.0, max_bgm_pitch)
		bgm.pitch_scale = snappedf(pitch, 0.25)
		print(t, " - ", pitch, " -> ", bgm.pitch_scale)

func _crunch_mode_spawn_time(doc_count: int = document_stack.actual_document_count):
	var x = max(doc_count, 1)
	return max(crunch_start_spawn_time - (log(x) / log(10)) * 1.8, crunch_min_spawn_time)


func _spawn_document(await_start = false):
	var delta = (document_stack.actual_document_count - boss_documents) - 2
	if GameManager.is_ceo() and boss_attack_timer.is_stopped() and delta > 0 and start_stack.actual_document_count >= 5 and not attacking:
		_boss_attack()
	else:
		var invalid_chance = GameManager.difficulty.invalid_word_chance
		var doc = doc_spawner.spawn_document(invalid_chance) as Document
		_add_document(doc, await_start)

func _add_document(doc: Document, await_start := false):
	doc.started.connect(func(): GameManager.start_type())
	doc.finished.connect(func():
		GameManager.finish_type(doc.word, doc.mistakes)
		player_doc_label.text = "%s" % document_stack.total_points
		
		if doc.is_discarded:
			doc.move_to(doc.global_position + Vector2.DOWN * 200)
		else:
			doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
			person_container.add_document()

		overload_progress.reduce(overload_reduce)
		overload_timer.stop()
		
		document_stack.add_document(doc.mistakes > 0, doc_spawner.is_invalid_word(doc.word), doc.is_discarded, doc.word)
		documents.erase(doc)
		
		if not work_time.is_day_ended() and GameManager.is_work_mode():
			distractions.maybe_show_distraction()

		if documents.size() > 0:
			documents[0].highlight()
			
			if documents.size() < min_documents:
				_spawn()
		elif work_time.is_day_ended():
			_finished()
		else:
			if await_start:
				keyboard.frame = 0
				_start_game()
			else:
				spawn_timer.stop()
				_spawn()
			
		if Input.is_action_pressed("special_mode"):
			shift_overlay.add_highlight()
	)

	if documents.is_empty():
		doc.highlight()
		
	if await_start:
		doc.show_tutorial()
	
	documents.append(doc)

func get_label():
	if documents.is_empty(): return null
	return documents[0].get_label()


#### CEO ####
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
	
func _ceo_game_ended():
	var data = {
		"total": document_stack.total_points,
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

	#end.open(data, boss_data)

func _process(delta: float) -> void:
	if is_gameover or not GameManager.is_ceo(): return
	
	boss_processing += delta
	if boss_processing >= boss_process_speed and start_stack.has_documents():
		boss_processing = 0
		boss_documents += 1
		start_stack.remove_document()
