class_name ShiftButtons
extends Control

signal activated(active)

@export var overlay: Control
@export var feedback_btn: Control
@export var delegator: Delegator

@onready var shift_original := position
@onready var feedback_original := feedback_btn.position

var sync_feedback_pos := true # some weird bug with the button position
var was_shift := false
var tw: Tween

func _ready() -> void:
	overlay.modulate = Color.TRANSPARENT
	
	await get_tree().physics_frame
	feedback_original = feedback_btn.position
	get_tree().create_timer(0.1).timeout.connect(func(): sync_feedback_pos = false)

func _physics_process(delta: float) -> void:
	if not was_shift and sync_feedback_pos:
		feedback_btn.position = feedback_original + Vector2.DOWN * size.y

func handle_event(event: InputEvent) -> bool:
	if not event is InputEventKey: return false
	if not event.is_pressed() and not event.is_action("special_mode"): return false
	
	var shift = event.is_action_pressed("special_mode") or Input.is_action_pressed("special_mode")
	if not shift:
		if was_shift:
			close()
			return true
		
		return false
	
	if not was_shift:
		sync_feedback_pos = false
		if open_effect():
			activated.emit(true)
			was_shift = true
			return true
		return false
	
	delegator.handle_event(event)
	return true

#func is_shift_pressed(event: InputEventKey):
	#return event and (event.keycode == KEY_SHIFT or event.shift_pressed) and event.pressed

func close():
	close_effect()
	activated.emit(false)
	was_shift = false

func open_effect():
	if tw and tw.is_running():
		return false
		
	tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel().set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay, "modulate", Color.WHITE, 0.5)
	tw.tween_property(self, "position", shift_original + Vector2.DOWN * size.y, 0.5)
	tw.tween_property(feedback_btn, "position", feedback_original, 0.5)
	return true

func close_effect():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel().set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay, "modulate", Color.TRANSPARENT, 0.5)
	tw.tween_property(self, "position", shift_original, 0.5)
	tw.tween_property(feedback_btn, "position", feedback_original + Vector2.DOWN * size.y, 0.5)
	return true
