class_name Delegator
extends Node

@export var nodes: Array[Control] = []

func handle_event(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		for node in nodes:
			node.get_label().reset()
		return

	var key = KeyReader.get_key_of_event(event)
	if key:
		var focused = _get_focused_label()
		if focused:
			focused.handle_key(key)
		else:
			var first = _get_first_label_starting(key)
			if first:
				first.handle_key(key)

	get_viewport().set_input_as_handled()

func has_focused():
	return _get_focused_label() != null

func _get_first_label_starting(key: String):
	for m in nodes:
		var lbl = m.get_label() as TypedWord
		if lbl and lbl.word != "" and lbl.word.begins_with(key):
			return lbl
	return null

func _get_focused_label():
	for m in nodes:
		var lbl = m.get_label() as TypedWord
		if lbl and lbl.word != "" and lbl.focused:
			return lbl
	return null