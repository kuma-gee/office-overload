class_name ContractDocument
extends FocusedDocument

@export var container: Control
@export var esc: Control
@export var mutators_label: Label

func _ready() -> void:
	for c in container.get_children():
		delegator.nodes.append(c)

	esc.hide()
	focus_entered.connect(func(): esc.show())
	focus_exited.connect(func(): esc.hide())
	opened.connect(func(): _update_label())
	super._ready()

func _update_label():
	var infos = GameManager.get_active_mutator_infos()
	if infos.is_empty():
		infos = "(none active)"
	var text = "Contract:\n%s" % infos
	if GameManager.has_mutators_unlocked() and not GameManager.has_all_mutators_active():
		text += "\nTurn on all policies to unlock new ones"
	mutators_label.text = text
