extends Node2D

signal finished()

@onready var sprite = $Sprite2D
@onready var rich_text_label = $RichTextLabel
@onready var type_sound = $TypeSound
@onready var control = $Control
@onready var paper_move_out = $PaperMoveOut
@onready var paper_move_in = $PaperMoveIn
@onready var paper_sort = $PaperSort

var typed := ""
var word := ""
var target_position := Vector2.ZERO
var highlighted = false

var _logger = Logger.new("Document")

func _update_word():
	rich_text_label.text = "[center][typed until=%s]%s[/typed][/center]" % [typed.length(), word]

func _ready():
	_update_word()
	rich_text_label.position += Vector2.DOWN * 50
	
	sprite.material.set_shader_parameter("enable", false)
	sprite.material = sprite.material.duplicate()
	control.mouse_entered.connect(func(): 
		if highlighted:
			sprite.material.set_shader_parameter("enable", true)
	)
	control.mouse_exited.connect(func(): 
		if highlighted:
			sprite.material.set_shader_parameter("enable", false)
	)
	control.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and highlighted and abs(global_rotation) > 0.001:
			create_tween().tween_property(self, "global_rotation", 0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_CUBIC)
			paper_sort.play()
	)
	
func move_to(pos, rot_offset = PI/15, move_in = false):
	var tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "global_position", pos, 1.0)
	var random_rot = randf_range(-rot_offset, rot_offset)
	tween.tween_property(self, "global_rotation", random_rot, 1.0)
	
	if move_in:
		paper_move_in.play()
	else:
		paper_move_out.play()

func handle_key(key: String):
	if typed.length() == word.length():
		return
	
	var next_word_char = word[typed.length()]
	if next_word_char == key.to_lower():
		typed += key.to_lower()
		_update_word()
		type_sound.play()
		if typed == word:
			finished.emit()

func highlight():
	rich_text_label.add_theme_constant_override("outline_size", 5)
	highlighted = true

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
