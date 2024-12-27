class_name DocumentUI
extends Control

@export var move_dir := Vector2.UP
@onready var orig_pos := global_position

var tw: Tween

func open(delay = 0.0, offset_x := 0.0):
	var offset = Vector2.LEFT * offset_x
	global_position = orig_pos - move_dir * size.y + offset
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", orig_pos + offset, 1.0).set_delay(delay)

func close():
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", orig_pos - move_dir * size.y, 1.0)
