extends Node2D

signal finished()

@onready var sprite = $Sprite2D
@onready var label = $Word
@onready var typed_label = $Typed
@onready var control = $Control

var typed := ""
var word := ""
var target_position := Vector2.ZERO
var highlighted = false

var _logger = Logger.new("Document")

func _ready():
	label.text = word
	label.position += Vector2.DOWN * 50
	
	label.label_settings = label.label_settings.duplicate()
	
	typed_label.text = word
	typed_label.position = label.position
	typed_label.visible_characters = 0
	
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
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and highlighted:
			create_tween().tween_property(self, "global_rotation", 0, 1.0) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_CUBIC)
	)
	
func move_to(pos, with_rotation = true, rot_offset = PI/15):
	var tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "global_position", pos, 1.0)
	
	if with_rotation:
		#var is_long_word = word.contains(" ") or word.length() >= 10
		var random_rot = randf_range(-rot_offset, rot_offset)
		tween.tween_property(self, "global_rotation", random_rot, 1.0)

func handle_key(key: String):
	if typed.length() == word.length():
		return
	
	var next_word_char = word[typed.length()]
	var is_space = next_word_char == " "
	if is_space: # there should only at most be one space
		next_word_char = word[typed.length() + 1]
	
	if next_word_char.to_lower() == key.to_lower():
		if is_space:
			typed += " "
		
		typed += key
		typed_label.visible_characters = typed.length()
		
		if typed.to_lower() == word.to_lower():
			finished.emit()

func highlight():
	var setting = label.label_settings as LabelSettings
	setting.outline_size = 5
	highlighted = true

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
