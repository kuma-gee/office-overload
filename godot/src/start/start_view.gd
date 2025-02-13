class_name StartView
extends Control

signal closed()

@export var delegator: Delegator
@export var light: Light2D

@onready var light_orig_pos = light.global_position
@onready var camera := get_viewport().get_camera_2d()

var tw: Tween
var init := false
var is_open := false

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		closed.emit()
	
	delegator.handle_event(event)

func open() -> void:
	is_open = true

	_init_papers()
	if not GameManager.is_motion:
		camera.position_smoothing_enabled = false
		camera.global_position = global_position
		light.global_position = global_position
		return
	
	camera.position_smoothing_enabled = true
	tw = create_tween().set_ease(Tween.EaseType.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tw.tween_property(camera, "global_position", global_position, 0.5)
	tw.tween_property(light, "global_position", global_position, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

func _init_papers():
	if not init:
		setup_papers()
		init = true

func setup_papers():
	pass

func close() -> void:
	if not GameManager.is_motion:
		camera.position_smoothing_enabled = false
		camera.global_position = Vector2.ZERO
		light.global_position = light_orig_pos
		return
	
	camera.position_smoothing_enabled = true
	tw = create_tween().set_ease(Tween.EaseType.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tw.tween_property(camera, "global_position", Vector2.ZERO, 0.5)
	tw.tween_property(light, "global_position", light_orig_pos, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	is_open = false
