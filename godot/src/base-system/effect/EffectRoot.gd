class_name EffectRoot
extends Node

var tw := TweenCreator.new(self)
var effects: Array[Effect] = []

func add_effect(n: Effect):
	effects.append(n)
	
func do_effect():
	var finish_cb = []
	if tw.new_tween(func(): _do_callbacks(finish_cb)):
		for eff in effects:
			var cb = eff.apply(tw)
			if cb:
				finish_cb.append(cb)

func _do_callbacks(cbs: Array):
	for cb in cbs:
		cb.call()

func reverse_effect():
	var finish_cb = []
	if tw.new_tween(func(): _do_callbacks(finish_cb)):
		for eff in effects:
			var cb = eff.reverse(tw)
			if cb:
				finish_cb.append(cb)
