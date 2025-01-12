class_name FocusedDocument
extends DocumentUI

signal opened()
signal closed()

@export var title_button: TypingButton
@export var delegator: Delegator
@export var offset_y := 0

@onready var orig_rot := rotation

var focus_tw: Tween

func _ready() -> void:
	super._ready()
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_IGNORE
	
	title_button.finished.connect(func(): grab_focus())
	focus_entered.connect(func():
		if focus_tw and focus_tw.is_running(): return
		focus_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
		focus_tw.tween_property(self, "position", Vector2(-size.x / 2, -(size.y / 2) + offset_y), 0.5)
		focus_tw.tween_property(self, "rotation", 0, 0.5)
		focus_tw.tween_callback(func(): z_index = 10)
		title_button.get_label().fill_all = true
		delegator.focus()
		opened.emit()
	)
	focus_exited.connect(func():
		if focus_tw and focus_tw.is_running(): return
		focus_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
		focus_tw.tween_property(self, "global_position", orig_pos, 0.5)
		focus_tw.tween_property(self, "rotation", orig_rot, 0.5)
		focus_tw.tween_callback(func(): z_index = 0)
		title_button.get_label().fill_all = false
		delegator.unfocus()
		closed.emit()
	)
	
	delegator.unfocus()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)

func get_label():
	return title_button.get_label()
