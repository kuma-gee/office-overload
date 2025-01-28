extends FocusedDocument

@export var container: Control
@export var esc: Control

func _ready() -> void:
	for c in container.get_children():
		delegator.nodes.append(c)

	esc.hide()
	focus_entered.connect(func(): esc.show())
	focus_exited.connect(func(): esc.hide())
	super._ready()
