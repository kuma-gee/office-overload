class_name DocumentUI
extends Control

@export var include_rotation := false
@export var move_dir := Vector2.UP
@onready var orig_pos := global_position

var tw: Tween

func is_open():
	return global_position == orig_pos

func open(delay = 0.0, offset_x := 0.0):
	var offset = Vector2.LEFT * offset_x
	var dir = move_dir * size.y
	if include_rotation:
		dir = dir.rotated(rotation)
	
	global_position = orig_pos - dir + offset
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", orig_pos + offset, 1.0).set_delay(delay)

func close():
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", orig_pos - move_dir * size.y, 1.0)
