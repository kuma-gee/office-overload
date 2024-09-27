class_name Shake
extends Effect

func apply(tw: TweenCreator):
	node.pivot_offset = node.size / 2
	
	var dur = tw.default_duration / 9
	var start = node.rotation
	
	var ease = Tween.EASE_OUT
	var trans = Tween.TRANS_BOUNCE
	var rot = PI/50
	for _i in range(3):
		tw.tw.tween_property(node, "rotation", start - rot, dur).set_trans(trans).set_ease(ease)
		tw.tw.set_parallel(false).tween_property(node, "rotation", start + rot, dur).set_trans(trans).set_ease(ease)
		tw.tw.set_parallel(false).tween_property(node, "rotation", start, dur).set_trans(trans).set_ease(ease)
		rot /= 2
	
func stop(tw: TweenCreator):
	node.rotation = 0.0
