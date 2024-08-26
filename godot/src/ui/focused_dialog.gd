class_name FocusedDialog
extends Control

@export var delegator: Delegator

@onready var effect_root = $EffectRoot

func _ready():
	hide()
	focus_entered.connect(func():
		show()
		effect_root.do_effect()
	)
	focus_exited.connect(func():
		effect_root.reverse_effect()
	)
