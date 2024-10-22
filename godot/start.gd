extends Control

@export var work_performance: AltTypingButton
@export var setting_leaderboard: AltTypingButton
@export var exit_quitjob: AltTypingButton
@export var feedback: TypingButton

@export_category("Nodes") # onready does not work on web builds?? 
@export var shift_container: ShiftButtons
@export var settings: Settings
@export var game_modes: GameModesDialog
@export var delegator: Delegator
@export var leaderboard: Leaderboard
@export var feedback_ui: FeedbackUI
@export var performance_graph: PerformanceGraph
@export var quit_warning_dialog: QuitJobWarning

@onready var shift_buttons := [work_performance, setting_leaderboard, exit_quitjob]

var is_starting := false
var quit_warning_open := false

func _ready():
	get_tree().paused = false
	GameManager.game_started.connect(func(): is_starting = true)
	
	work_performance.finished.connect(func():
		var modes = GameManager.get_unlocked_modes()
		if modes.size() == 1 or Env.is_demo():
			GameManager.start(GameManager.Mode.Work)
		else:
			game_modes.grab_focus()
	)
	work_performance.finished_alt.connect(func(): performance_graph.open())
	
	setting_leaderboard.finished.connect(func(): settings.grab_focus())
	setting_leaderboard.finished_alt.connect(func(): leaderboard.open())
	
	exit_quitjob.finished.connect(func(): GameManager.quit_game())
	exit_quitjob.finished_alt.connect(func(): quit_warning_dialog.grab_focus())
	
	feedback.finished.connect(func(): feedback_ui.open())
	
	shift_container.visible = GameManager.has_played
	shift_container.activated.connect(func(active):
		for btn in shift_buttons:
			btn.set_active(active)
		feedback.reset()
		
		exit_quitjob.disabled = active and not GameManager.has_current_job()
	)
	
	for btn in shift_buttons:
		btn.finished_alt.connect(func(): shift_container.close())
	feedback.finished.connect(func(): shift_container.close())

func _unhandled_input(event: InputEvent) -> void:
	if is_starting: return
	if get_viewport().gui_get_focus_owner() != null: return
	if shift_container.handle_event(event): return
	
	delegator.handle_event(event)

func _notification(what) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		shift_container.close()
