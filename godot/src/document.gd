class_name Document
extends Node2D

signal started()
signal finished()

@onready var sprite = $Sprite2D
@onready var typing_label = $TypingLabel
@onready var control = $Control
@onready var paper_move_out = $PaperMoveOut
@onready var paper_move_in = $PaperMoveIn
@onready var paper_sort = $PaperSort

var mistakes := 0
var word := ""
var target_position := Vector2.ZERO
var _logger = Logger.new("Document")

func show_tutorial():
	typing_label.highlight_first = true

func _ready():
	typing_label.word = word
	typing_label.type_start.connect(func(): started.emit())
	typing_label.type_finish.connect(func(): finished.emit())
	typing_label.position += Vector2.DOWN * 50
	
	sprite.material.set_shader_parameter("enable", false)
	sprite.material = sprite.material.duplicate()
	
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
	if not typing_label.handle_key(key):
		mistakes += 1

func highlight():
	typing_label.focused = true

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
