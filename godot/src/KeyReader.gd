class_name KeyReader
extends Node

signal pressed_key(key, shift)
signal pressed_cancel(shift)
signal use_coffee()

var last_key := ""

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		pressed_cancel.emit(event.shift_pressed)
		return
	
	if event.is_action_pressed("coffee_action") and GameManager.item_count(Shop.Items.COFFEE) > 0:
		use_coffee.emit()
		return
	
	if event.is_released():
		last_key = ""
	
	var key = get_key_of_event(event)
	if not key or last_key == key: return
	
	last_key = key
	
	#print("[%s] Handling input %s" % [get_path(), event])
	pressed_key.emit(key.to_lower(), event.shift_pressed)
	get_viewport().set_input_as_handled()

static func get_key_of_event(ev: InputEvent):
	if not ev is InputEventKey or not ev.pressed: return null
	
	var key = ev.duplicate() as InputEventKey
	
	# we don't care about modifiers
	#key.shift_pressed = false # we need special characters
	key.ctrl_pressed = false
	key.alt_pressed = false
	key.meta_pressed = false
	
	var text = char(key.unicode).to_lower()
	if text.length() != 1:
		return null
	
	return text
