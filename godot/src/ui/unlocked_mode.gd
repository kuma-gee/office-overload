class_name UnlockedMode
extends Control

@export var label: Label
@onready var original_pos := global_position
@onready var hide_pos := original_pos + Vector2(0.2, 1) * 150

var tw: Tween

func _ready() -> void:
	hide()

func unlocked_mode(mode: GameManager.Mode):
	open(0.4)
	label.text = "%s" % GameManager.Mode.keys()[mode]

func open(delay := 0.0):
	global_position = hide_pos
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", original_pos, 1.0).set_delay(delay)
	show()
