class_name MutatorToggle
extends HBoxContainer

@export var mutator: GameManager.Mutator
@export var label: TypedWord
@export var checkbox: CheckBox

func _ready():
	label.word = GameManager.get_mutator_name(mutator)
	label.type_finish.connect(func(): GameManager.toggle_mutator(mutator))
	GameManager.mutator_toggled.connect(func(m):
		if m == mutator:
			_update()
	)
	GameManager.mutator_unlocked.connect(func(m):
		if m == mutator:
			visible = true
			_update()
	)
	visible = mutator in GameManager.unlocked_mutators
	_update()

func _update():
	checkbox.button_pressed = GameManager.is_mutator_active(mutator)

func get_label() -> TypedWord:
	return label
