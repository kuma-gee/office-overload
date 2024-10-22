class_name QuitJobWarning
extends FocusedDialog

@export var effect: EffectRoot
@export var quit_button_yes: TypingButton
@export var quit_button_no: TypingButton

func _ready() -> void:
	super._ready()
	quit_button_yes.finished.connect(func():
		GameManager.reset_values()
		get_viewport().gui_release_focus()
	)
	quit_button_no.finished.connect(func(): get_viewport().gui_release_focus())

func _gui_input(event):
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)
	get_viewport().set_input_as_handled()
