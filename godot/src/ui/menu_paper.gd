class_name MenuPaper
extends Control

@export var label: TypedWord

@onready var original_pos = position
@onready var original_rot = rotation

@onready var idx := name.to_int()
@onready var delegator: Delegator = $Delegator

var tw: Tween
var previous_focus: Control

func _ready() -> void:
	close()
	
	label.type_finish.connect(func():
		previous_focus = get_viewport().gui_get_focus_owner()
		label.reset()
		grab_focus()
	)
	focus_entered.connect(func(): focused())
	focus_exited.connect(func(): defocused())

func get_label():
	return label

func close():
	var offset = idx * Vector2.RIGHT * 10
	offset += Vector2.DOWN * 50
	tw = _create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tw.tween_property(self, "rotation", 0, 0.5)
	tw.tween_property(self, "position", -size / 2 + offset, 0.5)
		
func open():
	tw = _create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tw.tween_property(self, "rotation", original_rot, 0.5)
	tw.tween_property(self, "position", original_pos, 0.5)

func focused():
	tw = _create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "rotation", 0, 0.5)
	tw.parallel().tween_property(self, "position", -size/2 + Vector2.UP * 100, 0.5)
	
	tw.tween_callback(func(): z_index = 100)
	tw.tween_property(self, "position", -size/2, 0.5)
	label.highlight_first = false
	label.focused = true

func defocused():
	tw = _create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	tw.tween_property(self, "position", -size/2 + Vector2.UP * 100, 0.5)
	
	tw.tween_callback(func(): z_index = 0)
	tw.tween_property(self, "rotation", original_rot, 0.5)
	tw.parallel().tween_property(self, "position", original_pos, 0.5)
	label.highlight_first = true
	label.focused = false

func send():
	tw = _create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position", position + Vector2.UP * 200, 0.5)
	await tw.finished
	hide()
	
	rotation = original_rot
	position = original_pos
	z_index = 0
	go_back()

func _create_tween() -> Tween:
	if tw and tw.is_running():
		tw.kill()
	
	return create_tween()

func go_back():
	if previous_focus:
		previous_focus.grab_focus()
	else:
		get_viewport().gui_release_focus()
	

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		go_back()
	
	delegator.handle_event(event)
	get_viewport().set_input_as_handled()
