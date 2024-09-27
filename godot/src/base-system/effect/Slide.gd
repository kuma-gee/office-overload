class_name Slide
extends Effect

@export var dir := Vector2.UP
@export var flip := false

func _ready():
	super._ready()
	node.position -= dir * node.size

func apply(tw: TweenCreator):
	if flip:
		tw.slide_out(node, -dir).set_ease(Tween.EASE_OUT)
	else:
		tw.slide_in(node, dir)

func reverse(tw: TweenCreator):
	if flip:
		tw.slide_in(node, dir).set_ease(Tween.EASE_IN)
	else:
		tw.slide_out(node, -dir)
