class_name MutatorToggle
extends Control

@export var mutator: GameManager.Mutator
@export var label: TypedWord
@export var checkbox: CheckBox
@export var desc_label: Label
@export var overlay: Control

func _ready():
	label.type_finish.connect(func(): GameManager.toggle_mutator(mutator))
	GameManager.mutator_toggled.connect(func(m):
		if m == mutator:
			_update()
	)
	GameManager.mutator_unlocked.connect(func(m):
		if m == mutator:
			_update()
	)
	_update()

func _update():
	var unlocked: bool = mutator in GameManager.unlocked_mutators
	var name := GameManager.get_mutator_name(mutator)
	label.word = name if unlocked else _censor(name)
	label.disabled = not unlocked
	checkbox.visible = unlocked
	#overlay.visible = not unlocked
	checkbox.button_pressed = GameManager.is_mutator_active(mutator)
	desc_label.text = GameManager.get_mutator_desc(mutator)
	desc_label.modulate.a = 1.0 if unlocked else 0.0

func _censor(w: String) -> String:
	var censored := ""
	for c in w:
		censored += " " if c == " " else "?"
	return censored

func get_label() -> TypedWord:
	return label
