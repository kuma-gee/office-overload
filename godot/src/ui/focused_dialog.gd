class_name FocusedDialog
extends Control

@export var delegator: Delegator
@export var overlay: ColorRect
@export var sliders: Array[TypingSlider] = []

@onready var effect_root = $EffectRoot

var active_slider: TypingSlider:
	set(v):
		if active_slider:
			active_slider.z_index = 0
		
		active_slider = v
		overlay.visible = v != null
		
		if active_slider:
			active_slider.z_index = 20

func _ready():
	overlay.hide()
	focus_entered.connect(func():
		show()
		effect_root.do_effect()
	)
	focus_exited.connect(func():
		effect_root.reverse_effect()
	)

	for s in sliders:
		s.opened.connect(func(open): active_slider = s if open else null)

func _gui_input(event):
	if active_slider:
		active_slider.handle_event(event)
	else:
		if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
			get_viewport().gui_release_focus()
		
		delegator.handle_event(event)

	get_viewport().set_input_as_handled()
