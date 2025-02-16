class_name FocusedDocument
extends DocumentUI

signal opened()
signal closed()

@export var overlay: ColorRect
@export var title_button: TypingButton
@export var delegator: Delegator
@export var offset_y := 0
@export var start_center := false
@export var use_focus := true

@onready var orig_rot := rotation

var focus_tw: Tween
var is_focus_open := false

func set_active(v: bool):
	title_button.get_label().highlight_first = v
	if overlay:
		overlay.visible = not v

func _ready() -> void:
	super._ready()
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_IGNORE
	if overlay:
		overlay.hide()
	
	if title_button and use_focus:
		title_button.finished.connect(func(): grab_focus())
	
	focus_entered.connect(func(): focus_open())
	focus_exited.connect(func(): focus_close())
	
	delegator.unfocus()
	
	if start_center:
		to_center(false)

func to_center(motion = GameManager.is_motion):
	if not motion:
		position = _center_pos()
		rotation = 0
		return
	
	_create_tw()
	focus_tw.tween_property(self, "position", _center_pos(), 0.5)
	focus_tw.tween_property(self, "rotation", 0, 0.5)
	await focus_tw.finished

func _center_pos():
	return Vector2(-size.x / 2, -(size.y / 2) + offset_y)

func _create_tw():
	if focus_tw and focus_tw.is_running():
		focus_tw.kill()
	
	focus_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()

func to_original_pos():
	if not GameManager.is_motion:
		position = orig_pos
		rotation = orig_rot
		return
	
	_create_tw()
	focus_tw.tween_property(self, "position", orig_pos, 0.5)
	focus_tw.tween_property(self, "rotation", orig_rot, 0.5)
	await focus_tw.finished

func focus_open():
	is_focus_open = true
	
	var pos = _center_pos()
	if not GameManager.is_motion:
		position = pos
		rotation = 0
		z_index = 10
	else:
		_create_tw()
		focus_tw.tween_property(self, "position", pos, 0.5)
		focus_tw.tween_property(self, "rotation", 0, 0.5)
		focus_tw.tween_callback(func(): z_index = 10)
	
	if title_button:
		title_button.get_label().fill_all = true
	
	delegator.focus()
	opened.emit()
	SoundManager.play_paper_open()

func focus_close():
	is_focus_open = false
	if focus_tw and focus_tw.is_running():
		focus_tw.kill()
		
	if not GameManager.is_motion:
		position = _get_final_pos()
		rotation = orig_rot
		z_index = 0
	else:
		focus_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
		focus_tw.tween_property(self, "position", _get_final_pos(), 0.5)
		focus_tw.tween_property(self, "rotation", orig_rot, 0.5)
		focus_tw.tween_callback(func(): z_index = 0)
	
	if title_button:
		title_button.get_label().fill_all = false
	
	delegator.unfocus()
	closed.emit()
	SoundManager.play_paper_close()

func _gui_input(event: InputEvent) -> void:
	if not handle_input(event):
		get_viewport().gui_release_focus()

func handle_input(event: InputEvent):
	if focus_tw and focus_tw.is_running():
		return true
	
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		return false
	
	delegator.handle_event(event)
	return true

func get_label():
	return title_button.get_label()
