extends Control

@export var tween_trans := Tween.TRANS_CUBIC
@export var label: TypedWord
@export var type := Distraction.Type.EMAIL
@export var effect_root: EffectRoot

@export var slide_dir := Vector2.ZERO
@export var sounds: Array[AudioStreamPlayer] = []

@onready var start_pos := global_position

var is_open := false
var tw: Tween
var mistakes := 0

func _ready():
	label.type_start.connect(func(): GameManager.start_type())
	label.type_finish.connect(func():
		GameManager.finish_type(label.word, mistakes)
		slide_out()
	)
	label.type_wrong.connect(func(): mistakes += 1)
	
	hide()

func set_word(w: String):
	label.word = w
	label.highlight_first = true
	label.focused = true
	slide_in()
	show()

func get_word():
	return label.word

func slide_in():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(tween_trans)
	tw.tween_property(self, "global_position", start_pos, 0.5).from(get_hide_position())
	tw.finished.connect(func(): if effect_root: effect_root.do_effect())
	is_open = true
	for s in sounds:
		s.play()

func slide_out():
	if tw and tw.is_running():
		tw.kill()
	
	if effect_root:
		effect_root.stop()
	
	tw = create_tween().set_ease(Tween.EASE_IN).set_trans(tween_trans)
	tw.tween_property(self, "global_position", get_hide_position(), 0.5)
	tw.finished.connect(func(): label.reset(""))
	
	is_open = false
	for s in sounds:
		s.stop()

func get_hide_position():
	return start_pos - slide_dir

func get_label():
	return label
