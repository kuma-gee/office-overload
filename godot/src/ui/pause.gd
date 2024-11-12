class_name Pause
extends Control

@onready var effect_root: EffectRoot = $EffectRoot
@onready var delegator: Delegator = $Delegator

@export var quit_btn: TypingButton
@export var continue_btn: TypingButton

func _ready() -> void:
	hide()
	focus_entered.connect(func(): _on_focused())
	focus_exited.connect(func(): _on_focus_exited())
	continue_btn.finished.connect(func(): get_viewport().gui_release_focus())
	quit_btn.finished.connect(func():
		GameManager.back_to_menu()
		#GameManager.reset_values()
	)

func _on_focused():
	get_tree().paused = true
	effect_root.do_effect()
	show()
	
func _on_focus_exited():
	get_tree().paused = false
	effect_root.reverse_effect()

func _gui_input(event: InputEvent) -> void:
	delegator.handle_event(event)
