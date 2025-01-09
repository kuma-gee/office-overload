extends FocusedDocument

@export var container: Control

func _ready() -> void:
	for c in container.get_children():
		delegator.nodes.append(c)

	super._ready()
