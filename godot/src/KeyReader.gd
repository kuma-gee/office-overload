class_name KeyReader
extends Node

signal pressed_key(key, shift)
signal pressed_cancel(shift)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		pressed_cancel.emit(event.shift_pressed)
		return
	
	var key = get_key_of_event(event)
	if not key: return
	
	print("[%s] Handling input %s" % [get_path(), event])
	pressed_key.emit(key.to_lower(), event.shift_pressed)
	get_viewport().set_input_as_handled()

static func get_key_of_event(ev: InputEvent):
	if not ev is InputEventKey or not ev.pressed: return null
	
	var key = ev.duplicate() as InputEventKey
	
	# we don't care about modifiers
	key.shift_pressed = false
	key.ctrl_pressed = false
	key.alt_pressed = false
	key.meta_pressed = false
	
	var text = key.as_text().to_lower()
	if text.length() != 1:
		return null
	return text
