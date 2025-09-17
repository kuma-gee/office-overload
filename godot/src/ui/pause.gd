class_name Pause
extends Control

@onready var effect_root: EffectRoot = $EffectRoot
@onready var delegator: Delegator = $Delegator
@onready var panel_container: EndPaper = $PanelContainer

@export var quit_btn: TypingButton
@export var continue_btn: TypingButton
@export var label: Label
@export var title_label: Label

func _ready() -> void:
	hide()
	focus_entered.connect(func(): _on_focused())
	focus_exited.connect(func(): _on_focus_exited())
	continue_btn.finished.connect(func(): get_viewport().gui_release_focus())
	quit_btn.finished.connect(func():
		GameManager.back_to_menu()
	)

func _on_focused():
	# Using text wrap makes the dialog longer for some reason
	# So we add line breaks ourselves
	if not GameManager.is_multiplayer_mode():
		title_label.text = "Break"
		label.text = "I'm on a coffee break.
I'll be back in a
minute"
		quit_btn.word = "home"
		get_tree().paused = true
	else:
		title_label.text = "No Break!"
		label.text = "Your co-workers are
stillcompeting with
you"
		quit_btn.word = "leave"
	
	effect_root.do_effect()
	panel_container.open()
	show()
	
func _on_focus_exited():
	get_tree().paused = false
	effect_root.reverse_effect()
	panel_container.close()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused() and not effect_root.is_running():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)
