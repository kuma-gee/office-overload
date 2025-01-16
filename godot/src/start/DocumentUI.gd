class_name DocumentUI
extends Control

@export var include_rotation := false
@export var move_dir := Vector2.UP
@export var extra_distance := 0.0
@export var original_pos_offset_y := 0.0
@export var play_sound := true

@onready var orig_pos := global_position

var tw: Tween
var was_opened := false

func _ready() -> void:
	hide()

func _get_final_pos():
	return orig_pos + Vector2(0, original_pos_offset_y)

func is_open():
	return was_opened

func open(delay = 0.0):
	var dir = move_dir * size.y
	if include_rotation:
		dir = dir.rotated(rotation)
	dir += Vector2.UP * extra_distance
	
	global_position = _get_final_pos() - dir
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel()
	tw.tween_property(self, "global_position", _get_final_pos(), 1.0).set_delay(delay)
	if play_sound:
		tw.tween_callback(func(): SoundManager.play_paper_move()).set_delay(delay)
	was_opened = true
	show()

func close():
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", _close_position(), 1.0)

func _close_position():
	return _get_final_pos() - move_dir * size.y + Vector2.DOWN * extra_distance

func send():
	tw = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position", position + Vector2.UP * 200, 0.5)
	await tw.finished
	hide()
	
