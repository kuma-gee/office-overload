class_name Document
extends Node2D

const ACTIVE_GROUP = "ActiveDocument"

signal started()
signal finished()
signal typed()

@export var rotation_offset := PI/20
@export var random_flip := false

@onready var sprite = $Sprite2D
@onready var typing_label = $Sprite2D/TypingLabel
@onready var control = $Control
@onready var paper_move_out = $PaperMoveOut
@onready var paper_move_in = $PaperMoveIn
@onready var paper_sort = $PaperSort

# const TRASH_PREFIX = "!"
var is_discarded := false

var mistakes := 0
var word := ""
var censored := []
var target_position := Vector2.ZERO
var _logger = Logger.new("Document")
var move_out_pos

func get_label():
	return typing_label

func show_tutorial():
	typing_label.highlight_first = true

func _ready():
	typing_label.word = word
	typing_label.censored = censored
	typing_label.typing.connect(func(): typed.emit())

	typing_label.type_start.connect(func(): started.emit())
	typing_label.type_finish.connect(func():
		remove_from_group(ACTIVE_GROUP)
		finished.emit()
	)
	#typing_label.position += Vector2.DOWN * 50
	
	sprite.material.set_shader_parameter("enable", false)
	sprite.material = sprite.material.duplicate()
	
	if random_flip:
		sprite.flip_h = randf() > 0.5
	
func move_to(pos, move_in = false, return_pos = null):
	move_out_pos = return_pos
	
	var tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", pos, 1.0)
	
	var random_rot = randf_range(-rotation_offset, rotation_offset)
	tween.tween_property(self, "global_rotation", random_rot, 1.0)
	
	if move_in:
		paper_move_in.play()
	else:
		paper_move_out.play()

func return_to():
	if move_out_pos:
		move_to(move_out_pos)

func handle_key(key: String):
	var hit = typing_label.handle_key(key)
	if not hit:
		mistakes += 1
	return hit

func highlight():
	typing_label.locked = true
	add_to_group(ACTIVE_GROUP)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func enable_trash():
	#typing_label.word = TRASH_PREFIX + word
	#typing_label.highlight_first = true
	z_index = 100
	is_discarded = true

func reset_word():
	#typing_label.word = word
	#typing_label.highlight_first = false
	z_index = 0
	is_discarded = false
