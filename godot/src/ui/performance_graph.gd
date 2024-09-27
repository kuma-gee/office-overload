class_name PerformanceGraph
extends Control

@export var graph: Graph2D
@export var effect: EffectRoot

@export var left_button: TypingButton
@export var right_button: TypingButton

@onready var main_color = Color("#353540")
@onready var delegator: Delegator = $Delegator

var main: PlotItem

func _ready() -> void:
	main = graph.add_plot_item("", main_color, 1.0)

	left_button.get_label().focused = true
	right_button.get_label().focused = true
	
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
	main.remove_all()
	
	var wpms = GameManager.past_wpms
	
	graph.x_max = wpms.size()
	graph.y_max = 250
	
	for i in wpms.size():
		main.add_point(Vector2(i, wpms[i]))

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().gui_release_focus()
		return
	
	var key = KeyReader.get_key_of_event(event)
	if key:
		if key == left_button.get_word():
			left_button.finished.emit()
			SoundManager.play_type_sound()
		elif key == right_button.get_word():
			right_button.finished.emit()
			SoundManager.play_type_sound()
		
	get_viewport().set_input_as_handled()
