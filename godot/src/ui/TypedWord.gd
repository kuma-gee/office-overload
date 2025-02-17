@tool
class_name TypedWord
extends RichTextLabel

signal typing()
signal type_finish()
signal type_start()
signal type_wrong()

@export var shake_amount := 20
@export var frequency := 8.0
@export var height := 2.0
@export var reset_on_finish := false

@export var untyped_color := Color.BLACK
@export var highlight_color := Color.WHITE
@export var typed_color := Color.WHITE
@export var untyped_outline_color := Color.WHITE
@export var untyped_outline_size := 2
@export var play_sound := true
@export var enable_mistake_effect := true

@export var center := true:
	set(v):
		center = v
		update_word()
@export var right := false:
	set(v):
		right = v
		update_word()

@onready var shake_timer: Timer = $ShakeTimer

@export_category("Type Effect")
@export var fill_all := false:
	set(v):
		fill_all = v
		update_word()
@export var outline_all := false:
	set(v):
		outline_all = v
		update_word()
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
		#word = word.replace(" ", "")
		typed = ""
		update_word()

@export var typed = "":
	set(v):
		typed = v
		update_word()

@export var focused := false:
	set(v):
		focused = v
		
		if not locked:
			add_theme_color_override("font_outline_color", highlight_color if v else Color.TRANSPARENT)
			update_word()

@export var jump_first := false:
	set(v):
		jump_first = v
		update_word()

var active := false:
	set(v):
		active = v
		update_word()

var current_shake := 0.0:
	set(v):
		current_shake = v
		if current_shake > 0:
			$ShakeTimer.start()
		else:
			$ShakeTimer.stop()
		update_word()

var locked := false:
	set(v):
		locked = v
		add_theme_color_override("font_outline_color", highlight_color if v else Color.TRANSPARENT)
		update_word()

var disabled := false
var censored := []:
	set(v):
		censored = v
		update_word()

func _ready():
	self.focused = false
	add_theme_constant_override("outline_size", 5)
	shake_timer.timeout.connect(func(): self.current_shake = 0)
	
	if reset_on_finish:
		type_finish.connect(func(): reset())

#func _gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#type_finish.emit()

func play_mistake_effect():
	self.current_shake = shake_amount
	update_word()
	SoundManager.play_type_mistake()

func get_remaining_word():
	return word.substr(typed.length())

func update_word():
	if active:
		text = _wrap_center("[outline_color=%s][color=%s]%s[/color][/outline_color]" % [highlight_color.to_html(), typed_color.to_html(), word])
		return
	
	if fill_all:
		text = _wrap_center("[color=%s]%s[/color]" % [typed_color.to_html(), word])
		return
	
	var until = typed.length()
	if highlight_first and until == 0:
		text = _outline(_wrap_center(_wrap_word(0, true)))
	elif highlight_all:
		text = _outline(_wrap_center(_wrap_typed(word.length(), _wrap_word(0))))
	else:
		text = _outline(_wrap_center(_wrap_typed(until, _wrap_word(until), true)))

func _outline(w: String, color: Color = untyped_outline_color):
	return "[outline_color=%s]%s[/outline_color]" % [color.to_html(), w]

func _outline_size(w: String, i: int):
	return "[outline_size=%s]%s[/outline_size]" % [i, w]

func _color(w: String, color: Color):
	return "[color=%s]%s[/color]" % [color.to_html(), w]

func _wrap_word(until: int, highlight_letter = false):
	var censored_word = word
	for i in censored:
		if i < until or i >= censored_word.length(): continue
		censored_word[i] = "_"

	#var highlight_start = "[outline_color=%s][color=%s]" % [Color.TRANSPARENT.to_html(), typed_color.to_html()]
	#var highlight_end = "[/color][/outline_color]"
	
	var not_highlight_char = _outline(_outline_size(censored_word.substr(until, 1), untyped_outline_size), highlight_color if highlight_first else Color.TRANSPARENT)
	var first_highlight = _outline(_outline_size(_color(censored_word.substr(until, 1), typed_color), untyped_outline_size), highlight_color)
	var first_jump = _wrap_typed(1, first_highlight)
	return "[color=%s]%s[/color][color=%s][shake rate=%s level=%s]%s[/shake]%s[/color]" % [
		typed_color.to_html(),
		_outline(censored_word.substr(0, until), highlight_color),
		#untyped_color.to_html() if typed.length() > 0 else text_color.to_html(),
		untyped_color.to_html(),
		#highlight_start if highlight_letter else "",
		current_shake, 10 if current_shake > 0 else 0,
		first_jump if jump_first and until == 0 else (first_highlight if highlight_first and until == 0 else not_highlight_char),
		#highlight_end if highlight_letter else "",
		_outline(_outline_size(censored_word.substr(until + 1), untyped_outline_size), untyped_outline_color if locked else Color.TRANSPARENT)
	]

func _wrap_typed(until: int, w: String, highlight = false):
	var highlight_text = ""
	if highlight:
		highlight_text = "highlight_falloff=%s highlight_normal=%s" % [20., typed_color.to_html()]
	
	return "[typed until=%s height=%s frequency=%s %s]%s[/typed]" % [until, height if GameManager.is_motion else 0, frequency, highlight_text, w]

func _wrap_center(w: String):
	if right:
		return "[right]%s[/right]" % w
	
	if not center: return w
	return "[center]%s[/center]" % w

func _next_char():
	if typed.length() >= word.length():
		return null
	return word[typed.length()]

const MAPPING = {
	"à": "a",
	"á": "a",
	"ǎ": "a",
	"ā": "a",
	"ì": "i",
	"í": "i",
	"ǐ": "i",
	"ī": "i",
	"ò": "o",
	"ó": "o",
	"ǒ": "o",
	"ō": "o",
	"ù": "u",
	"ú": "u",
	"ū": "u",
	"ǔ": "u",
	"ē": "e",
	"è": "e",
	"é": "e",
	"ě": "e",
}

func handle_key(key: String, ignore_error = false):
	if not is_visible_in_tree() or key == " ":
		return false
	
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
	elif typed != word and not ignore_error:
		if enable_mistake_effect:
			play_mistake_effect()
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

func get_label():
	return self
