extends Sprite2D

@onready var label: Label = $Label

var word := ""

func _ready() -> void:
	label.visible = word != "" and GameManager.is_work_mode()
	label.text = "-%s" % word.length()
