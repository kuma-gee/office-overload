class_name Delegator
extends Node

@export var reset_on_mistake := false
@export var nodes: Array[Control] = []

var last_event: InputEvent

func handle_event(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		for node in nodes:
			if node and node.get_label():
				node.get_label().reset()
				
		get_viewport().set_input_as_handled()
		return
		
	var key = KeyReader.get_key_of_event(event)
	var handled = false
	if key:
		if last_event and last_event is InputEventKey and last_event.keycode == event.keycode and last_event.pressed == event.pressed:
			return

		var focused = _get_focused_label()
		if focused:
			handled = focused.handle_key(key)
			if not handled and reset_on_mistake:
				focused.reset()
		else:
			var first = _get_first_label_starting(key)
			if first:
				handled = first.handle_key(key)

	last_event = event
	get_viewport().set_input_as_handled()
	return handled

func has_focused():
	return _get_focused_label() != null

func _get_first_label_starting(key: String):
	for m in nodes:
		var lbl = m.get_label()
		if lbl.word.begins_with(key) and _is_valid_node(lbl):
			return lbl
	return null

func _get_focused_label():
	for m in nodes:
		var lbl = m.get_label()
		if _is_valid_node(lbl) and lbl.focused:
			return lbl
	
	return null

func _is_valid_node(label: TypedWord):
	return label and label.is_visible_in_tree() and label.word != "" and label.modulate.a >= 1
