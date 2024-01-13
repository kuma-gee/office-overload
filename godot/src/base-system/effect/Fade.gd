class_name Fade
extends Effect

func _ready():
	super._ready()
	node.hide()

func apply(tw: TweenCreator):
	tw.fade_in(node)
	node.show()

func reverse(tw: TweenCreator):
	tw.fade_out(node)
	return func(): node.hide()
