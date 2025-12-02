class_name Pause
extends Control

signal quit()

@onready var effect_root: EffectRoot = $EffectRoot
@onready var delegator: Delegator = $Delegator
@onready var panel_container: EndPaper = $PanelContainer

@export var zen_scores: ZenScores
@export var quit_btn: TypingButton
@export var continue_btn: TypingButton
@export var label: Label
@export var title_label: Label

var is_open := false

func _ready() -> void:
	hide()
	#focus_entered.connect(func(): _on_focused())
	#focus_exited.connect(func(): _on_focus_exited())
	continue_btn.finished.connect(func(): close())
	quit_btn.finished.connect(func(): quit.emit())

func open():
	if is_open: return
	is_open = true
	# Using text wrap makes the dialog longer for some reason
	# So we add line breaks ourselves
	if not GameManager.is_multiplayer_mode():
		title_label.text = "Break"
		label.text = "You are taking a
coffee break"
		quit_btn.word = "home"
		get_tree().paused = true
	elif Networking.is_status_connected():
		title_label.text = "No Break!"
		label.text = "Your co-workers are
still competing with
you"
		quit_btn.word = "leave"
	else:
		get_tree().paused = true
		title_label.text = "Disconnected!"
		label.text = "The owner left the
office"
		quit_btn.word = "leave"
	
	effect_root.do_effect()
	panel_container.open()
	show()
	
	if GameManager.is_zen_mode():
		zen_scores.slide_in(0.2)
	
func close():
	if not is_open: return
	is_open = false
	
	get_tree().paused = false
	effect_root.reverse_effect()
	panel_container.close()

	if GameManager.is_zen_mode():
		zen_scores.slide_out(0.1)

func _input(event: InputEvent) -> void:
	if not is_open: return
	
	if get_viewport().gui_get_focus_owner() != null: return
	
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused() and not effect_root.is_running():
		close()
	
	delegator.handle_event(event)
	get_viewport().set_input_as_handled()
