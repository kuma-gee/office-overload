class_name Scale
extends Effect

func _ready():
	super._ready()

func apply(tw: TweenCreator):
	tw.scale_in(node)

func reverse(tw: TweenCreator):
	tw.scale_out(node)
