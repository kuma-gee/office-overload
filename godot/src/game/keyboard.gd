extends GameDeskItem

@onready var shift: ColorRect = $Shift
@onready var esc: ColorRect = $ESC
@onready var ctrl: ColorRect = $Ctrl
@onready var backspace: ColorRect = $Backspace
@onready var space: ColorRect = $Space
@onready var _1: ColorRect = $"123/1"
@onready var _2: ColorRect = $"123/2"
@onready var _3: ColorRect = $"123/3"
@onready var _4: ColorRect = $"123/4"
@onready var _5: ColorRect = $"123/5"
@onready var _6: ColorRect = $"123/6"
@onready var _7: ColorRect = $"123/7"
@onready var _8: ColorRect = $"123/8"
@onready var _9: ColorRect = $"123/9"
@onready var _0: ColorRect = $"123/0"
@onready var minus: ColorRect = $"123/minus"
@onready var equal: ColorRect = $"123/equal"
@onready var q: ColorRect = $QWE/q
@onready var w: ColorRect = $QWE/w
@onready var e: ColorRect = $QWE/e
@onready var r: ColorRect = $QWE/r
@onready var t: ColorRect = $QWE/t
@onready var y: ColorRect = $QWE/y
@onready var u: ColorRect = $QWE/u
@onready var i: ColorRect = $QWE/i
@onready var o: ColorRect = $QWE/o
@onready var p: ColorRect = $QWE/p
@onready var bracket_left: ColorRect = $QWE/bracket_left
@onready var bracket_right: ColorRect = $QWE/bracket_right
@onready var a: ColorRect = $ASD/a
@onready var s: ColorRect = $ASD/s
@onready var d: ColorRect = $ASD/d
@onready var f: ColorRect = $ASD/f
@onready var g: ColorRect = $ASD/g
@onready var h: ColorRect = $ASD/h
@onready var j: ColorRect = $ASD/j
@onready var k: ColorRect = $ASD/k
@onready var l: ColorRect = $ASD/l
@onready var semicolon: ColorRect = $ASD/semicolon
@onready var single_quote: ColorRect = $ASD/single_quote
@onready var backslash: ColorRect = $ASD/backslash
@onready var z: ColorRect = $ZXC/z
@onready var x: ColorRect = $ZXC/x
@onready var c: ColorRect = $ZXC/c
@onready var v: ColorRect = $ZXC/v
@onready var b: ColorRect = $ZXC/b
@onready var n: ColorRect = $ZXC/n
@onready var m: ColorRect = $ZXC/m
@onready var comma: ColorRect = $ZXC/comma
@onready var period: ColorRect = $ZXC/period
@onready var slash: ColorRect = $ZXC/slash

@onready var KEY_MAP = {
	KEY_0: _0,
	KEY_1: _1,
	KEY_2: _2,
	KEY_3: _3,
	KEY_4: _4,
	KEY_5: _5,
	KEY_6: _6,
	KEY_7: _7,
	KEY_8: _8,
	KEY_9: _9,
	KEY_A: a,
	KEY_B: b,
	KEY_C: c,
	KEY_D: d,
	KEY_E: e,
	KEY_F: f,
	KEY_G: g,
	KEY_H: h,
	KEY_I: i,
	KEY_J: j,
	KEY_K: k,
	KEY_L: l,
	KEY_M: m,
	KEY_N: n,
	KEY_O: o,
	KEY_P: p,
	KEY_Q: q,
	KEY_R: r,
	KEY_S: s,
	KEY_T: t,
	KEY_U: u,
	KEY_V: v,
	KEY_W: w,
	KEY_X: x,
	KEY_Y: y,
	KEY_Z: z,
	KEY_BACKSPACE: backspace,
	KEY_ESCAPE: esc,
	KEY_SHIFT: shift,
	KEY_SPACE: space,
	KEY_CTRL: ctrl,
	KEY_MINUS: minus,
	KEY_EQUAL: equal,
	KEY_SEMICOLON: semicolon,
	KEY_COMMA: comma,
	KEY_PERIOD: period,
	KEY_SLASH: slash,
	KEY_BRACKETLEFT: bracket_left,
	KEY_BRACKETRIGHT: bracket_right,
}

func _ready() -> void:
	for rect in KEY_MAP.values():
		rect.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key = event as InputEventKey
		var rect = KEY_MAP.get(key.keycode)
		if rect:
			rect.visible = key.pressed
