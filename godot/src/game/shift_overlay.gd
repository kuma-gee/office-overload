class_name ShiftOverlay
extends Node

@export var game: Game
@export var overlay: ColorRect
@export var delegator: Delegator
@export var distractions: Distraction

var tw: Tween

func _ready() -> void:
	_hide_overlay()
	distractions.distraction_shown.connect(func(): _remove_highlight()) # just highlight because they are sharing the overlay node

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not (GameManager.is_manager() or GameManager.is_ceo()): return
	if game.is_gameover: return
	if not distractions.get_active_words().is_empty(): return

	var key_ev = event as InputEventKey
	if key_ev.is_action_released("special_mode"):
		_hide_overlay()
	
	if key_ev.is_action_pressed("special_mode"):
		_show_overlay()
	
	if not Input.is_action_pressed("special_mode"): return
	
	delegator.handle_event(event)

func _hide_overlay():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.TRANSPARENT, 0.5)
	_remove_highlight()

func _remove_highlight():
	var doc = get_tree().get_first_node_in_group(Document.ACTIVE_GROUP)
	if doc:
		doc.reset_word()

func _show_overlay():
	if tw and tw.is_running():
		tw.kill()
	
	overlay.show()
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.WHITE, 0.5)
	add_highlight()

func add_highlight():
	var doc = get_tree().get_first_node_in_group(Document.ACTIVE_GROUP)
	if doc:
		doc.enable_trash()
