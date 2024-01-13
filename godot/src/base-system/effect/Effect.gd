class_name Effect
extends Node

@export var node: Node

@onready var effect_root: EffectRoot = get_parent()

func _ready():
	if effect_root:
		effect_root.add_effect(self)
	else:
		push_warning("Effect cannot be added without root: %s" % get_path())

func apply(tw: TweenCreator):
	pass
	
func reverse(tw: TweenCreator):
	pass
