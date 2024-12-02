class_name PromotionPaper
extends PanelContainer

signal accepted()
signal declined()

@export var yes_button: TypingButton
@export var no_button: TypingButton

@onready var original_pos := global_position
@onready var hide_pos := original_pos + Vector2.DOWN * 180

var tw: Tween

func _ready() -> void:
	hide()
	
	yes_button.finished.connect(func():
		GameManager.take_promotion()
		accepted.emit()
		close()
	)
	no_button.finished.connect(func():
		declined.emit()
		close()
	)

func close():
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "position", hide_pos, 1.0)
	await tw.finished
	hide()

func open(delay: float):
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	
	global_position = hide_pos
	tw.tween_property(self, "global_position", original_pos, 1.0).set_delay(delay)
	show()
