class_name EffectRoot
extends Node

signal finished()

@export var trans := Tween.TRANS_CUBIC
@export var ease := Tween.EASE_IN
@export var duration := 1.0
@export var loop := false

var tw := TweenCreator.new(self)
var effects: Array[Effect] = []

func _ready():
	tw.ease = ease
	tw.trans = trans
	tw.default_duration = duration
	tw.loop = loop

func add_effect(n: Effect):
	effects.append(n)
	
func do_effect(kill_previous = true):
	if not kill_previous and tw.is_running():
		return
	
	var finish_cb = []
	if tw.new_tween(func(): _do_callbacks(finish_cb)):
		for eff in effects:
			tw.tw.set_parallel()
			var cb = eff.apply(tw)
			if cb:
				finish_cb.append(cb)

func _do_callbacks(cbs: Array):
	for cb in cbs:
		cb.call()

func reverse_effect():
	var finish_cb = [func(): finished.emit()]
	if tw.new_tween(func(): _do_callbacks(finish_cb)):
		for eff in effects:
			var cb = eff.reverse(tw)
			if cb:
				finish_cb.append(cb)

func stop():
	tw.kill()
	for eff in effects:
		eff.stop(tw)
