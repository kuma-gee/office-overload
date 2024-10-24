class_name GameMode
extends MarginContainer

const DESC = {
	GameManager.Mode.Work: "Get tasks based on your skill. (story)",
	GameManager.Mode.Crunch: "Work until you burn out. (endless)",
	GameManager.Mode.Interview: "Tests your skills. (timed)",
}
const TEXT = {
	GameManager.Mode.Work: "Work time",
	GameManager.Mode.Crunch: "Crunch time",
	GameManager.Mode.Interview: "Job interview",
}

@export var typing_button: TypingButton
@export var label: Label
@export var lock_fg: Control
@export var mode := GameManager.Mode.Crunch

func _ready() -> void:
	typing_button.word = TEXT[mode]
	typing_button.update()
	
	label.text = DESC[mode]
	_update()
	
	typing_button.finished.connect(func(): GameManager.start(mode))

func _update():
	var unlocked = GameManager.is_mode_unlocked(mode)
	label.visible = unlocked
	lock_fg.visible = not unlocked
	typing_button.get_label().highlight_first = unlocked

func get_label():
	if not label.visible: return null
	return typing_button.get_label()
