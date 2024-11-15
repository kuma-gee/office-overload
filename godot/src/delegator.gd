class_name Delegator
extends Node

@export var nodes: Array[Node] = []

var last_event: InputEvent

func reset():
	for node in nodes:
		if node and node.get_label():
			node.get_label().reset()

func handle_event(event: InputEvent):
	if event.is_action_pressed("clear_word"):
		reset()
		get_viewport().set_input_as_handled()
		return
		
	var key = KeyReader.get_key_of_event(event)
	var handled = false
	if key:
		if last_event and last_event is InputEventKey and last_event.keycode == event.keycode and last_event.pressed == event.pressed:
			return

		var focused = _get_focused_label()
		if focused.is_empty():
			focused = nodes
		
		var not_handled = []
		for node in focused:
			if node and node.get_label():
				var was_handled = node.get_label().handle_key(key, true)
				if not was_handled:
					not_handled.append(node)

				if not handled and was_handled:
					handled = true
		
		if handled:
			for node in not_handled:
				node.get_label().reset()

	last_event = event
	get_viewport().set_input_as_handled()
	return handled

func has_focused():
	return not _get_focused_label().is_empty()

func _get_labels_starting(key: String, label_nodes: Array):
	var labels = []
	for m in label_nodes:
		var lbl = m.get_label()
		if lbl.word.begins_with(key) and _is_valid_node(lbl):
			labels.append(lbl)

	return labels

func _get_focused_label():
	var labels = []
	for m in nodes:
		var lbl = m.get_label()
		if _is_valid_node(lbl) and lbl.focused:
			labels.append(lbl)
	
	return labels

func _is_valid_node(label: TypedWord):
	return label and label.is_visible_in_tree() and label.word != "" and label.modulate.a >= 1 and not label.active
