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
@export var boss_process_speed := 2.0
@export var boss_process_speed_variation := 0.2
@export var boss_max_combo_count := 15
@export var boss_min_combo_count := 5
@export var boss_combo_failure_rate := 0.15

@export var boss_doc_label: Label
@export var boss_combo_label: Label
@export var boss_attack_timer: Timer
@export var player_doc_label: Label
@export var player_combo_label: Label

@export_category("Boss Attack")
@export var boss_document_max_diff_timer := 100
@export var boss_max_attack_time := 8.0
@export var boss_min_attack_time := 4.0
@export var boss_attack_count_min := 2
@export var boss_attack_count_max := 6
@export var spill_mug_chance := 0.3
@export var boss_hit_sound: AudioStreamPlayer
@export var spill_mug: SpillMug

@export_category("Crunch")
@export var max_bgm_pitch := 2.0
@export var max_bgm_pitch_time := 0.4
@export var crunch_start_spawn_time := 4.
@export var crunch_min_spawn_time := 0.5
@export var crunch_max_difficulty_count := 80
@export var crunch_documents: Label

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
@onready var shift_delegator: Delegator = $ShiftOverlay/ShiftDelegator

@onready var bgm = $BGM
@onready var end = $CanvasLayer/End
@onready var gameover: Gameover = $CanvasLayer/Gameover
@onready var key_reader = $KeyReader
@onready var pause: Pause = $CanvasLayer/Pause
@onready var day: Day = $CanvasLayer/HUD/Day
@onready var drink_sound: RandomPitchShift = $DrinkSound

@onready var camera_shake: CameraShake = $CameraShake
@onready var frame_freeze: FrameFreeze = $FrameFreeze

var is_gameover = false:
	set(v):
		is_gameover = v

var documents = []
var day_ended := false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	randomize()
	get_tree().paused = false
	_update_score()
	
	GameManager.pay_assistant()

	for i in range(items_root.get_child_count()):
		items_root.get_child(i).visible = (GameManager.is_item_used(i) and not GameManager.is_crunch_mode()) #or i >= Shop.Items.size()
	
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
	
	if GameManager.is_crunch_mode():
		animation_player.play("crunch")
	else:
		if GameManager.is_ceo():
			animation_player.play("ceo")
			work_time.hour_in_seconds = 5
		elif GameManager.is_senior():
			animation_player.play("messy")
		elif GameManager.is_manager():
			animation_player.play("littered")
		else:
			animation_player.play("no_mess")
	
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
		if documents.is_empty() or GameManager.is_ceo():
			_finished()
		day_ended = true
	)
	work_time.time_changed.connect(func(_t):
		if GameManager.is_crunch_mode(): return
		if day_ended and work_time.is_day_ended() and GameManager.is_intern():
			_finished()
	)
	
	shift_delegator.unhandled_key.connect(func(_key):
		if not is_time_running():
			return

		if get_label():
			document_stack.add_mistake()
			_update_score()
	)
	key_reader.pressed_key.connect(func(key, _shift):
		if not documents.is_empty():
			if documents[0].handle_key(key):
				document_stack.add_combo()
			elif not work_time.stopped:
				document_stack.add_mistake()
				_update_score()
	)
	key_reader.pressed_cancel.connect(func(_shift):
		if day.is_feature_open():
			day.close_feature()
			return
		
		if not is_gameover and not day.visible:
			pause.grab_focus()
	)
	key_reader.use_coffee.connect(func():
		var reduction = GameManager.use_coffee()
		overload_progress.reduce(reduction)
		drink_sound.play_random_pitched()
	)

func is_time_running():
	return not work_time.stopped and not is_gameover

func _on_day_finished():
	if GameManager.is_work_mode():
		bgm.pitch_scale = GameManager.difficulty.bgm_speed
	else:
		bgm.pitch_scale = 1.0
	
	_spawn_document(true)

func _start_game():
	if not GameManager.is_ceo() and GameManager.is_work_mode():
		animation_player.play("normal")
	
	key_reader.process_mode = Node.PROCESS_MODE_ALWAYS
	work_time.start()
	overload_progress.start()
	_update_score()
	
	get_tree().create_timer(0.5).timeout.connect(func():
		animation_player.play("start_bgm")
		if not bgm.playing:
			bgm.play()
	)
	
	if GameManager.is_ceo():
		boss_attack_timer.start()
	
	_spawn()
	
func _finished(is_burn_out = false, is_fired = false):
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
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
			
	elif GameManager.is_crunch_mode():
		_on_crunch_ended()
		
func _spawn():
	if (work_time.is_day_ended() and GameManager.is_work_mode()) or is_gameover:
		return
	
	_spawn_document()
	
	if GameManager.is_work_mode():
		if not GameManager.is_intern() and not GameManager.is_ceo():
			var day_multipler = min(remap(GameManager.performance, GameManager.get_min_performance(), GameManager.get_max_performance(), 1.0, 0.5), 1.0)
			var document_multipler = max(remap(documents.size(), 2, 15, 1.0, 5.0), 1.0)
			spawn_timer.start(GameManager.difficulty.base_document_time * day_multipler * document_multipler)
			
		if (GameManager.is_ceo() or (GameManager.is_intern() and GameManager.get_until_max_performance() <= 5)) and documents.size() < min_documents:
			await get_tree().create_timer(0.5).timeout
			_spawn()
	else:
		_update_crunch_values()

func _spawn_document(await_start = false):
	if GameManager.is_crunch_mode():
		var doc = doc_spawner.spawn_document() as Document
		_add_document(doc, await_start)
		return

	if GameManager.is_ceo() and boss_attack_timer.is_stopped() and _boss_doc_diff() > 0 and not is_attacking and boss_attack_documents <= 0:
		_setup_boss_attack()
	else:
		var invalid_chance = GameManager.difficulty.invalid_word_chance
		if GameManager.is_ceo() and boss_attack_documents > 0:
			var doc = doc_spawner.spawn_boss_document(invalid_chance)
			_add_document(doc, await_start)
			boss_attack_documents -= 1
			if boss_attack_documents <= 0:
				_start_boss_attack_timer()
		else:
			var doc = doc_spawner.spawn_document(invalid_chance if not await_start else 0.0) as Document
			_add_document(doc, await_start)

func _update_score():
	player_doc_label.text = "%s" % document_stack.tasks
	player_combo_label.text = "%sx" % document_stack.combo_count
	#player_combo_label.visible = document_stack.combo_count > 0
	
	single_player_doc_label.text = "$%s" % document_stack.total_points
	single_player_combo_label.text = "%sx" % document_stack.combo_count
	single_player_combo_label.visible = document_stack.combo_count > 0
	
	crunch_documents.text = "%s" % document_stack.actual_document_count

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
		
		document_stack.add_document(doc.mistakes, doc_spawner.is_invalid_word(doc.word), doc.is_discarded, doc.word)
		documents.erase(doc)
		
		_update_score()
		
		if not work_time.is_day_ended() and GameManager.is_work_mode():
			distractions.maybe_show_distraction()

		if documents.size() > 0:
			documents[0].highlight()
			documents[0].show_tutorial()
			
			if documents.size() < min_documents:
				_spawn()
		elif work_time.is_day_ended() and GameManager.is_work_mode():
			_finished()
		else:
			if await_start:
				keyboard.frame = 0
				_start_game()
			else:
				spawn_timer.stop()
				_spawn()
			
		if Input.is_action_pressed("special_mode") and distractions.get_active_words().is_empty():
			shift_overlay.add_highlight()
		
		if documents.size() > 0 and doc_spawner.is_invalid_word(documents[0].word):
			duck.play()
	)

	if documents.is_empty():
		doc.highlight()
		
	if await_start or documents.size() == 0:
		doc.show_tutorial()
	
	if await_start and not GameManager.has_played:
		keyboard.highlight_key(OS.find_keycode_from_string(doc.word[0]))
	
	documents.append(doc)

func get_label():
	if documents.is_empty(): return null
	return documents[0].get_label()

#region CRUNCH
func _update_crunch_values():
	var t = _crunch_mode_spawn_time()
	spawn_timer.start(t)
	print("Time: %s" % t)

	var d = _crunch_difficulty()
	doc_spawner.set_difficulty(d)
	
	# TODO: change at specific times for smoother transition ??
	var pitch = min(remap(document_stack.actual_document_count, 1.0, crunch_max_difficulty_count, 1.0, max_bgm_pitch), max_bgm_pitch)
	bgm.pitch_scale = snappedf(pitch, 0.25)

func _crunch_mode_spawn_time(doc_count: int = document_stack.actual_document_count):
	var x = max(doc_count, 1)
	return max(crunch_start_spawn_time - (log(x) / log(10)) * 1.5, crunch_min_spawn_time)

func _crunch_difficulty(doc_count: int = document_stack.actual_document_count):
	return clamp(float(doc_count) / crunch_max_difficulty_count, 0.0, 1.0)

func _on_crunch_ended():
	var data = GameManager.finished_crunch(document_stack.actual_document_count, work_time.hours_passed, document_stack.highest_streak)
	end.crunch_ended(data)
#endregion


#region CEO
var boss_documents := 0
var boss_points := 0:
	set(v):
		boss_points = v
		boss_doc_label.text = "%s" % boss_documents
var boss_combo := 0:
	set(v):
		boss_combo = v
		boss_combo_label.text = "%sx" % boss_combo
		#boss_combo_label.visible = boss_combo > 0
		
var boss_processing := 0.0
var boss_current_speed := boss_process_speed
var boss_mistakes := 0
var boss_attack_documents := 0
var boss_attacked := 0
var is_attacking := false

func _setup_boss_attack():
	is_attacking = true
	
	await _slam_desk()
	await _slam_desk()

	if not spill_mug.active and boss_attacked != 0 and (boss_attacked == 1 or randf() <= spill_mug_chance):
		_spill_boss_attack()
		boss_attack_documents = 0
		_start_boss_attack_timer()
	else:
		var min = boss_attack_count_min
		var max = boss_attack_count_max * GameManager.get_distraction_reduction()
		var p = _get_attack_percentage()
		min += (max - min) * p

		boss_attack_documents = randf_range(min, max)
		boss_attack_documents = floor(boss_attack_documents)
		_spawn_boss_attack()
	
	boss_attacked += 1
	is_attacking = false

func _slam_desk():
	camera_shake.shake()
	boss_hit_sound.play()
	for item in get_tree().get_nodes_in_group(GameDeskItem.GROUP):
		item.slammed()
	await get_tree().create_timer(0.5).timeout

func _spill_boss_attack():
	spill_mug.spill()

func _spawn_boss_attack():
	if boss_attack_documents <= 0: return
	
	for _i in range(boss_attack_documents):
		_spawn() # call normal spawn function to reset the normal document spawning
		await get_tree().create_timer(0.3).timeout

func _boss_doc_diff():
	return (document_stack.tasks - document_stack.wrong_tasks) - (boss_documents - boss_mistakes)

func _get_attack_percentage():
	var diff = _boss_doc_diff()
	if diff < 3:
		return 0.0
	elif diff < 6:
		return 0.5
	else:
		return 1.0

func _start_boss_attack_timer():
	var p = _get_attack_percentage()
	var time_diff = boss_max_attack_time - boss_min_attack_time
	var time = boss_min_attack_time + time_diff * (1-p)
	boss_attack_timer.start(time)

func _ceo_game_ended():
	end.ceo_ended({"tasks": document_stack.tasks, "mistakes": document_stack.wrong_tasks}, {"tasks": boss_documents, "mistakes": boss_mistakes})

func _process(delta: float) -> void:
	if is_gameover or not GameManager.is_ceo() or not is_time_running(): return
	
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
		
		if not failed:
			boss_combo += 1

		boss_current_speed = randf_range(boss_process_speed * (1 - boss_process_speed_variation), boss_process_speed * (1 + boss_process_speed_variation))
#endregion
