class_name Game
extends Node2D

@export var overload_reduce := 20.0
@export var work_time: WorkTime
@export var items_root: Node

@export_category("Work Mode")
@export var single_player_doc_label: Label
@export var single_player_combo_label: Label
@export var duck: Duck

@export_category("Boss")
@export var min_documents := 2
@export var boss_process_speed := 2.5
@export var boss_process_speed_variation := 0.3
@export var boss_max_combo_count := 15
@export var boss_min_combo_count := 6
@export var boss_combo_failure_rate := 0.2

@export var boss_doc_label: Label
@export var boss_combo_label: Label
@export var boss_attack_timer: Timer
@export var player_doc_label: Label
@export var player_combo_label: Label

@export_category("Boss Attack")
@export var boss_document_max_diff_timer := 100
@export var boss_max_attack_time := 10.0
@export var boss_min_attack_time := 5.0
@export var boss_attack_count_min := 2
@export var boss_attack_count_max := 4

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
@onready var shift_delegator: Delegator = $ShiftOverlay/ShiftDelegator

@onready var bgm = $BGM
@onready var end = $CanvasLayer/End
@onready var gameover: Gameover = $CanvasLayer/Gameover
@onready var key_reader = $KeyReader
@onready var pause: Pause = $CanvasLayer/Pause

@onready var camera_shake: CameraShake = $CameraShake
@onready var frame_freeze: FrameFreeze = $FrameFreeze

var is_gameover = false:
	set(v):
		is_gameover = v

var documents = []

func _set_environment():
	animation_player.play("normal")

func _ready():
	randomize()
	get_tree().paused = false
	_set_environment()
	_update_score()

	for i in range(items_root.get_child_count()):
		items_root.get_child(i).visible = i in GameManager.bought_items
	
	boss_combo = 0
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

	work_time.next_work_day.connect(func(): _finished(false, true))
	work_time.day_ended.connect(func():
		if documents.is_empty() or GameManager.is_intern() or GameManager.is_ceo():
			_finished()
	)
	
	shift_delegator.unhandled_key.connect(func(key):
		if get_label():
			document_stack.add_mistake()
			_update_score()
	)
	key_reader.pressed_key.connect(func(key, shift):
		if not documents.is_empty():
			if documents[0].handle_key(key):
				document_stack.add_combo()
			else:
				document_stack.add_mistake()
				_update_score()
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
	
func _finished(is_burn_out = false, is_fired = false):
	#self.is_gameover = is_burn_out or is_fired
	
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
				"stress": overload_progress.get_average(),
			}
			GameManager.finished_day(data)
			
			if is_burn_out:
				gameover.burnout()
			elif is_fired:
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
			var day_multipler = min(remap(GameManager.days_since_promotion, 1, 10, 1.0, 0.5), 1.0)
			var document_multipler = max(remap(documents.size(), 5, 15, 1.0, 5.0), 1.0)
			spawn_timer.start(GameManager.difficulty.base_document_time * day_multipler * document_multipler)
			
		if GameManager.is_ceo() and documents.size() < min_documents:
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
	if GameManager.is_ceo() and boss_attack_timer.is_stopped() and document_stack.total_points > boss_points and boss_attack_documents <= 0:
		_setup_boss_attack()
	else:
		if boss_attack_documents > 0:
			var doc = doc_spawner.spawn_invalid_document()
			_add_document(doc, await_start)
			boss_attack_documents -= 1
			if boss_attack_documents <= 0:
				_start_boss_attack_timer()
		else:
			var invalid_chance = GameManager.difficulty.invalid_word_chance
			var doc = doc_spawner.spawn_document(invalid_chance) as Document
			_add_document(doc, await_start)

func _update_score():
	player_doc_label.text = "%s" % document_stack.total_points
	player_combo_label.text = "%sx" % document_stack.combo_count
	player_combo_label.visible = document_stack.combo_count > 0
	
	single_player_doc_label.text = "%s" % document_stack.total_points
	single_player_combo_label.text = "%sx" % document_stack.combo_count
	single_player_combo_label.visible = document_stack.combo_count > 0

func _add_document(doc: Document, await_start := false):
	doc.started.connect(func(): GameManager.start_type())
	doc.finished.connect(func():
		GameManager.finish_type(doc.word, doc.mistakes)
		
		if doc.is_discarded:
			doc.move_to(doc.global_position + Vector2.DOWN * 200)
		else:
			doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))

		overload_progress.reduce(overload_reduce)
		overload_timer.stop()
		
		document_stack.add_document(doc.mistakes > 0, doc_spawner.is_invalid_word(doc.word), doc.is_discarded, doc.word)
		documents.erase(doc)
		
		_update_score()
		
		if not work_time.is_day_ended() and GameManager.is_work_mode():
			distractions.maybe_show_distraction()

		if documents.size() > 0:
			documents[0].highlight()
			documents[0].show_tutorial()
			
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
		
		if documents.size() > 0 and doc_spawner.is_invalid_word(documents[0].word):
			duck.play()
	)

	if documents.is_empty():
		doc.highlight()
		
	if await_start or documents.size() == 0:
		doc.show_tutorial()
	
	documents.append(doc)

func get_label():
	if documents.is_empty(): return null
	return documents[0].get_label()


#### CEO ####
var boss_documents := 0
var boss_points := 0:
	set(v):
		boss_points = v
		boss_doc_label.text = "%s" % boss_points
var boss_combo := 0:
	set(v):
		boss_combo = v
		boss_combo_label.text = "%sx" % boss_combo
		boss_combo_label.visible = boss_combo > 0
		
var boss_processing := 0.0
var boss_current_speed := boss_process_speed
var boss_mistakes := 0
var boss_attack_documents := 0

func _setup_boss_attack():
	camera_shake.shake()
	await get_tree().create_timer(0.5).timeout
	camera_shake.shake()
	await get_tree().create_timer(0.5).timeout

	boss_attack_documents = randi_range(boss_attack_count_min, boss_attack_count_max)
	_spawn_boss_attack()

func _spawn_boss_attack():
	if boss_attack_documents <= 0: return
	
	for _i in range(boss_attack_documents):
		_spawn() # call normal spawn function to reset the normal document spawning
		await get_tree().create_timer(0.25).timeout

func _start_boss_attack_timer():
	var doc_diff = document_stack.total_points - boss_points
	var p = clamp(doc_diff / boss_document_max_diff_timer, 0.0, 1.0)
		
	var time_diff = boss_max_attack_time - boss_min_attack_time
	var time = boss_min_attack_time + time_diff * (1-p)
	boss_attack_timer.start()

func _ceo_game_ended():
	var data = {
		"total": document_stack.total_points,
		"wrong": document_stack.wrong_tasks,
	}
	GameManager.calculate_performance(data)

	var boss_data = {
		"total": boss_points,
		"wrong": boss_mistakes,
	}
	GameManager.calculate_performance(boss_data)

	#end.open(data, boss_data)

func _process(delta: float) -> void:
	if is_gameover or not GameManager.is_ceo(): return
	
	boss_processing += delta
	if boss_processing >= boss_current_speed: #and start_stack.has_documents():
		var failed = false
		if boss_combo > boss_min_combo_count:
			var diff = max(boss_max_combo_count - boss_combo, 0)
			failed = randf() < boss_combo_failure_rate / (diff + 1)
			if failed:
				boss_combo = 0
				boss_mistakes += randi_range(1, 10)
		
		boss_processing = 0
		boss_points += 1 + 1 * boss_combo
		boss_documents += 1
		#start_stack.remove_document()
		
		if not failed:
			boss_combo += 1

		boss_current_speed = randf_range(boss_process_speed * (1 - boss_process_speed_variation), boss_process_speed * (1 + boss_process_speed_variation))
		print("Boss Finished, next speed %s" % boss_current_speed)
