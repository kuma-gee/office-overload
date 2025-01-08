class_name CeoLevelSelect
extends FocusedDialog

var is_starting := false

func _ready() -> void:
	super._ready()
	GameManager.game_started.connect(func(): is_starting = true)

func _gui_input(event):
	if is_starting: return
	
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)
	get_viewport().set_input_as_handled()
