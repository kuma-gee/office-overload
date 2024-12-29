class_name PerformanceGraph
extends MenuPaper

@export var graph: Graph2D

#@export var performance_button: TypingButton
#@export var wpm_button: TypingButton

@export var left_button: TypingButton
@export var right_button: TypingButton

@onready var main_color = Color("#353540")

var main: PlotItem
var plots = []

func _ready() -> void:
	super._ready()
	
	#visible = GameManager.past_performance.size() > 0
	
	#performance_button.finished.connect(func(): _update_performance_graph())
	#wpm_button.finished.connect(func(): _update_wpm_graph())
	
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

func open():
	#_update_performance_graph()
	_update_wpm_graph()
	super.open()

func _update_performance_graph():
	#_set_active(performance_button)
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
	graph.remove_all()
	main = graph.add_plot_item("", main_color, 1.0)

	var wpms = GameManager.past_wpms
	graph.x_max = wpms.size()
	graph.y_max = 200
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
