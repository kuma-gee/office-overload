class_name Haika
extends Control

@export var person_info_scene: PackedScene
@export var person_count := 3
@export var overlay: ColorRect
@export var delegator: Delegator

const NAMES = [
	"Steve",
	"John",
	"David",
	"Emma",
	"Linda",
	"Alice",
	"Wendy",
	"Raven",
	"Oliver",
	"Terry",
]

var tw: Tween

func _ready() -> void:
	for c in get_children():
		c.queue_free()
	
	if not GameManager.is_manager(): return
	
	var names = NAMES.duplicate()
	for i in person_count:
		var person_info = person_info_scene.instantiate()
		
		var n = names.pick_random()
		names.erase(n)
		person_info.set_word(n)
		
		add_child(person_info)
		delegator.nodes.append(person_info)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return

	var key_ev = event as InputEventKey
	if key_ev.is_action_released("special_mode"):
		_hide_overlay()
	
	if get_child_count() == 0: return
	
	if key_ev.is_action_pressed("special_mode"):
		_show_overlay()
	
	if not Input.is_action_pressed("special_mode"): return
	
	delegator.handle_event(event)

func _hide_overlay():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.TRANSPARENT, 0.5)
	
	for m in get_children():
		m.slide_out()
	
	delegator.reset()

func _show_overlay():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.WHITE, 0.5)
	
	for m in get_children():
		m.slide_in()
