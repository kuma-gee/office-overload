class_name TypedWord
extends RichTextLabel

signal typing()
signal type_finish()
signal type_start()

@export var height := 2.0
@export var text_color := Color.BLACK
@export var highlight_color := Color.WHITE
@export var typed_color := Color.WHITE
@export var type_sound: AudioStreamPlayer

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

func _ready():
	self.focused = false
	add_theme_constant_override("outline_size", 5)

func get_remaining_word():
	return word.substr(typed.length())

func update_word():
	var len = typed.length()
	if highlight_first and len == 0:
		text = "[center][typed until=1 height=%s]%s[/typed][/center]" % [height, word]
	else:
		text = "[center][typed until=%s height=%s][color=%s]%s[/color]%s[/typed][/center]" % [len, height, typed_color.to_html(), word.substr(0, len), word.substr(len)]

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
		
		if type_sound:
			type_sound.play()
		
		typed += key.to_lower()
		typed += " ".repeat(_get_num_of_spaces(typed.length()))
		typing.emit()
		
		if typed == word:
			type_finish.emit()
		return true
	
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
	
func reset():
	self.word = word
	self.focused = false
