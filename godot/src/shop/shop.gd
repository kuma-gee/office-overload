class_name Shop
extends Control

enum Items {
	RUBBER_DUCK,
	PLANT,
	COFFEE,
	ASSISTANT,
	MONEY_CAT,
}

const ITEM_FOLDER = "res://src/shop/items/"

signal closed()

@export var delegator: Delegator
@export var paper_container: Control
@export var money_container: Control
@export var light: Light2D

@onready var light_orig_pos = light.global_position
@onready var camera := get_viewport().get_camera_2d()

var tw: Tween
var init := false

func _ready() -> void:
	for c in paper_container.get_children():
		delegator.nodes.append(c)

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		closed.emit()
	
	delegator.handle_event(event)

func open() -> void:
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
		var delays = [0.5, 0.7, 0.7, 1.0, 0.9]
		for c in paper_container.get_children():
			if c is ShopPaper:
				if not GameManager.is_item_available(c.item.type): continue
				
				var i = 0 #randi_range(0, delays.size() - 1)
				if delays.is_empty():
					c.open(1.0)
				else:
					c.open(delays[i])
					delays.remove_at(i)
					
				c.opened.connect(func(): delegator.unfocus())
				c.closed.connect(func(): delegator.focus())
		init = true

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
