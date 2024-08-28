class_name TypedWord
extends RichTextLabel

signal typing()
signal type_finish()
signal type_start()
signal type_wrong()

@export var frequency := 8.0
@export var height := 2.0
@export var text_color := Color.BLACK
@export var highlight_color := Color.WHITE
@export var active_color := Color.WHITE
@export var typed_color := Color.WHITE
@export var play_sound := true
@export var center := true

@export var highlight_all := false:
	set(v):
		highlight_all = v
		update_word()
@export var highlight_first := false:
	set(v):
		highlight_first = v
		update_word()

@export var word = "":
	set(v):
		word = v.to_lower().strip_edges()
		#if remove_spaces:
		word = word.replace(" ", "")
		typed = ""
		update_word()

var typed = "":
	set(v):
		typed = v
		update_word()

var focused := false:
	set(v):
		focused = v
		add_theme_color_override("font_outline_color", highlight_color if v else Color.TRANSPARENT)
		update_word()

var active := false:
	set(v):
		active = v
		update_word()

func _ready():
	self.focused = false
	add_theme_constant_override("outline_size", 5)

func get_remaining_word():
	return word.substr(typed.length())

func update_word():
	if active:
		text = "[outline_color=%s][color=%s]%s[/color][/outline_color]" % [highlight_color.to_html(), active_color.to_html(), word]
		return
	
	var len = typed.length()
	if highlight_first and len == 0:
		text = _wrap_center(_wrap_typed(1, "[color=%s]%s[/color]" % [text_color.to_html(), word]))
	elif highlight_all:
		text = _wrap_center(_wrap_typed(word.length(), "[color=%s]%s[/color]" % [text_color.to_html(), word]))
	else:
		text = _wrap_center(_wrap_typed(len, "[color=%s]%s[/color][color=%s]%s[/color]" % [typed_color.to_html(), word.substr(0, len), text_color.to_html(), word.substr(len)]))

func _wrap_typed(until: int, w: String):
	return "[typed until=%s height=%s frequency=%s]%s[/typed]" % [until, height, frequency, w]

func _wrap_center(w: String):
	if not center: return w
	return "[center]%s[/center]" % w

func _next_char():
	if typed.length() >= word.length():
		return null
	return word[typed.length()]

func handle_key(key: String, grab_focus = true):
	var next_word_char = _next_char()
	if next_word_char == key.to_lower():
		if typed.length() == 0:
			type_start.emit()
			self.focused = true
		
		if play_sound:
			SoundManager.play_type_sound()
		
		typed += key.to_lower()
		typed += " ".repeat(_get_num_of_spaces(typed.length()))
		typing.emit()
		
		if typed == word:
			type_finish.emit()
		return true
	else:
		type_wrong.emit()
	
	return false

func get_word():
	return word

func set_typed(player_typed: String):
	self.focused = word.begins_with(player_typed) and player_typed != ""
	self.typed = player_typed if focused else ""
	
	if typed == word:
		type_finish.emit()

func _get_num_of_spaces(from: int):
	if from >= word.length():
		return 0

	var next_word_char = word[from]
	var count = 0
	while next_word_char == " ":
		count += 1
		next_word_char = word[from + count]
	return count

func cancel():
	self.focused = false
	
func reset(w = word):
	self.word = w
	self.focused = false
