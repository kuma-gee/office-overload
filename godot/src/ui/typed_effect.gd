# Ref: https://github.com/teebarjunk/godot-text_effects/blob/master/addons/teeb.text_effects/effects/Jump.gd
class_name TypedEffect
extends RichTextEffect

@export var amplitude := 2.0
@export var frequency := 8.0

# Syntax: [typed until=2][/typed]
var bbcode = "typed"

func _process_custom_fx(char_fx):
	var idx = char_fx.relative_index

	var until = char_fx.env.get("until", 0)
	if idx < until:
		var height = char_fx.env.get("height", amplitude)
		var offset = (until - idx - 1) * 6
		char_fx.offset.y -= _get_offset(char_fx.elapsed_time, offset, height)

	return true

func _get_offset(time: float, offset: int, amp = amplitude):
	return abs(sin(time * frequency + offset * PI * .025)) * amp
