class_name Flash
extends Effect

@export var flash_color := Color.RED
@onready var start_color: Color = node.modulate

func apply(tw: TweenCreator):
	var dur = tw.default_duration / 2
	tw.tw.tween_property(node, "modulate", flash_color, dur)
	tw.tw.set_parallel(false).tween_property(node, "modulate", start_color, dur)

func stop(tw: TweenCreator):
	node.modulate = Color.WHITE
