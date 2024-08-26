class_name GameModes
extends FocusedDialog

@export var work: TypingButton
@export var crunch: TypingButton
@export var interview: TypingButton

func _ready():
	super._ready()
	delegator.nodes = [work, crunch, interview]
	
	work.finished.connect(func(): GameManager.start(GameManager.Mode.Work))
	crunch.finished.connect(func(): GameManager.start(GameManager.Mode.Crunch))
	interview.finished.connect(func(): GameManager.start(GameManager.Mode.Interview))

func _gui_input(event):
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)

	get_viewport().set_input_as_handled()
