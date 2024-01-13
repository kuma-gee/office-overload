extends Node2D

signal finished()

@onready var label = $Word
@onready var typed_label = $Typed

var typed := ""
var word := ""
var target_position := Vector2.ZERO

var _logger = Logger.new("Document")

func _ready():
	label.text = word
	label.position += Vector2.DOWN * 50
	
	typed_label.text = word
	typed_label.position = label.position
	typed_label.visible_characters = 0
	
func move_to(pos, with_rotation = true):
	var tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "global_position", pos, 1.0)
	
	if with_rotation:
		var rot_offset = PI/8
		var random_rot = randf_range(-rot_offset, rot_offset)
		tween.tween_property(self, "global_rotation", random_rot, 1.0)

func handle_key(key: String):
	if typed.length() == word.length():
		return
	
	var next_word_char = word[typed.length()]
	var is_space = next_word_char == " "
	if is_space: # there should only at most be one space
		next_word_char = word[typed.length() + 1]
		
	_logger.debug("Next char for document: %s" % next_word_char)
	
	if next_word_char.to_lower() == key.to_lower():
		if is_space:
			typed += " "
		
		typed += key
		typed_label.visible_characters = typed.length()
		
		if typed.to_lower() == word.to_lower():
			finished.emit()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
