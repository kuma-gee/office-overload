class_name PerformanceGraph
extends Control

@export var graph: Graph2D
@export var effect: EffectRoot

@export var performance_button: TypingButton
@export var wpm_button: TypingButton

@export var left_button: TypingButton
@export var right_button: TypingButton

@onready var main_color = Color("#353540")
@onready var delegator: Delegator = $Delegator

var main: PlotItem
var plots = []

func _ready() -> void:
	performance_button.finished.connect(func(): _update_performance_graph())
	wpm_button.finished.connect(func(): _update_wpm_graph())
	
	left_button.finished.connect(func():
		var p = graph.first_plot.get_point_from_active(-1)
		if p:
			graph.first_plot.set_active_point(p)
	)
	right_button.finished.connect(func():
		var p = graph.first_plot.get_point_from_active(1)
		if p:
			graph.first_plot.set_active_point(p)
	)

	hide()
	focus_entered.connect(func():
		effect.do_effect()
		show()
	)
	focus_exited.connect(func():
		effect.reverse_effect()
	)

func open():
	grab_focus()
	_update_performance_graph()

func _update_performance_graph():
	_set_active(performance_button)
	graph.remove_all()
	main = graph.add_plot_item("", main_color, 1.0)
	
	var perf = GameManager.past_performance
	var next_diff = GameManager.next_difficulty
	var curr_diff = GameManager.difficulty
	var prev_diff = GameManager.prev_difficulty
	
	graph.x_max = perf.size()
	graph.y_max = (next_diff if next_diff else curr_diff).min_performance
	graph.y_min = max(prev_diff.min_performance - 10, 0) if prev_diff else 0
	
	for i in perf.size():
		main.add_point(Vector2(i, perf[i]))
	
	if next_diff:
		_add_plot_line(next_diff, perf.size())
	_add_plot_line(curr_diff, perf.size())

func _update_wpm_graph():
	_set_active(wpm_button)
	graph.remove_all()
	main = graph.add_plot_item("", main_color, 1.0)

	var wpms = GameManager.past_wpms
	graph.x_max = wpms.size()
	graph.y_max = 250
	for i in wpms.size():
		main.add_point(Vector2(i, wpms[i]))

func _add_plot_line(diff: DifficultyResource, max_x: int):
	var plot = graph.add_plot_item(GameManager.get_level_text(diff.level), Color.WHITE, 1)
	plot.show_points = false
	plot.add_point(Vector2(0, diff.min_performance))
	plot.add_point(Vector2(max_x, diff.min_performance))
	plots.append(plot)
	
	await get_tree().create_timer(0.1).timeout
	plot.update_legend()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
		get_viewport().set_input_as_handled()
		return
	
	#var key = KeyReader.get_key_of_event(event)
	#if key:
		#if key == left_button.get_word():
			#left_button.finished.emit()
			#SoundManager.play_type_sound()
			#get_viewport().set_input_as_handled()
			#return
		#elif key == right_button.get_word():
			#right_button.finished.emit()
			#SoundManager.play_type_sound()
			#get_viewport().set_input_as_handled()
			#return
		
	delegator.handle_event(event)

func _set_active(btn):
	_set_active_button(performance_button, false)
	_set_active_button(wpm_button, false)
	_set_active_button(btn, true)
	
func _set_active_button(btn: TypingButton, active = false):
	btn.get_label().highlight_first = not active
	btn.get_label().reset()
	btn.get_label().active = active
