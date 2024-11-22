extends Control

@onready var delegator: Delegator = $Delegator
@onready var end_effect: EffectRoot = $EndEffect

func _ready() -> void:
	hide()
	focus_entered.connect(func(): end_effect.do_effect())

func _gui_input(event: InputEvent) -> void:
	delegator.handle_event(event)
