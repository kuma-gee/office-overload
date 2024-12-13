# Ref: https://github.com/teebarjunk/godot-text_effects/blob/master/addons/teeb.text_effects/effects/Jump.gd
@tool
class_name TypedEffect
extends RichTextEffect

@export var amplitude := 2.0
@export var frequency := 8.0
@export var highlight_color := Color.WHITE

# Syntax: [typed until=2][/typed]
var bbcode = "typed"

func _process_custom_fx(char_fx):
	var idx = char_fx.relative_index

	var until = char_fx.env.get("until", 0)
	if idx < until:
		var height = char_fx.env.get("height", amplitude)
		var freq = char_fx.env.get("frequency", frequency)
		var offset = (until - idx - 1) * 6
		char_fx.offset.y -= _get_offset(char_fx.elapsed_time, offset, height, freq)
		
		var highlight_falloff = char_fx.env.get("highlight_falloff", null)
		var highlight_normal = char_fx.env.get("highlight_normal", null)
		if highlight_falloff and idx == until-1:
			var t = char_fx.elapsed_time
			var a = max(1. - pow(4 * t, highlight_falloff), 0.)
			highlight_color.a = a
			char_fx.color = Color(highlight_normal).blend(highlight_color)

	return true

func _get_offset(time: float, offset: int, amp = amplitude, freq = frequency):
	return abs(sin(time * freq + offset * PI * .025)) * amp
