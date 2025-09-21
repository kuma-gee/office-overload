class_name FocusedDialog
extends Control

@export var delegator: Delegator

@onready var effect_root = $EffectRoot

var is_starting := false

func _ready():
	hide()
	focus_entered.connect(func():
		show()
		effect_root.do_effect()
	)
	focus_exited.connect(func():
		effect_root.reverse_effect()
	)
	
	GameManager.game_started.connect(func(): is_starting = true)

func _gui_input(event):
	if is_starting: return
	
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)
	get_viewport().set_input_as_handled()
