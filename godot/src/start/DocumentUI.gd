class_name DocumentUI
extends Control

@export var include_rotation := false
@export var move_dir := Vector2.UP
@export var extra_distance := 0.0
@onready var orig_pos := global_position

var tw: Tween
var was_opened := false

func _ready() -> void:
	hide()

func is_open():
	return was_opened

func open(delay = 0.0):
	var dir = move_dir * size.y
	if include_rotation:
		dir = dir.rotated(rotation)
	dir += Vector2.UP * extra_distance
	
	global_position = orig_pos - dir
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", orig_pos, 1.0).set_delay(delay)
	was_opened = true
	show()

func close():
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", _close_position(), 1.0)

func _close_position():
	return orig_pos - move_dir * size.y + Vector2.DOWN * extra_distance
