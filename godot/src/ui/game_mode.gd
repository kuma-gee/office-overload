class_name GameMode
extends MarginContainer

const DESC = {
	GameManager.Mode.Work: "Get tasks based on your skill and improve until you become the next ceo.",
	#GameManager.Mode.Meeting: "Schedule a meeting with your teams and discuss to reduce the number of distractions.",
	#GameManager.Mode.AfterworkBeer: "Relax and have a beer with your team after a long day of work.",
	#GameManager.Mode.MorningCoffee: "Start your day with a cup of coffee that helps reduce your stress level.",

	GameManager.Mode.Crunch: "Work until you burn out. (endless)",
	#GameManager.Mode.Interview: "Tests your skills. (timed)",
	
	GameManager.Mode.Multiplayer: "Challenge other co-workers",
}

@export var typing_button: TypingButton
@export var label: Label
@export var lock_fg: Control
@export var mode := GameManager.Mode.Crunch

func _ready() -> void:
	typing_button.word = GameManager.get_mode_title(mode)
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
	if lock_fg.visible: return null
	return typing_button.get_label()
