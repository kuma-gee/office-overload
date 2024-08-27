class_name GameModesDialog
extends FocusedDialog

func _gui_input(event):
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)

	get_viewport().set_input_as_handled()
