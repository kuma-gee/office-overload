class_name Slide
extends Effect

@export var dir := Vector2.UP

func _ready():
	super._ready()
	node.position -= dir * node.size

func apply(tw: TweenCreator):
	tw.slide_in(node, dir)

func reverse(tw: TweenCreator):
	tw.slide_out(node, -dir)
