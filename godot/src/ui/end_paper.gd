class_name EndPaper
extends Control

@onready var original_pos := global_position
@onready var hide_pos := original_pos + Vector2.DOWN * 180

var tw: Tween

func _ready() -> void:
	hide()

func close():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tw.tween_property(self, "position", hide_pos, 1.0)
	tw.finished.connect(func(): hide())

func open(delay: float = 0.0):
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	
	global_position = hide_pos
	tw.tween_property(self, "global_position", original_pos, 1.0).set_delay(delay)
	show()
