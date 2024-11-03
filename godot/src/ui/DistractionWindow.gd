class_name DistractionItem
extends Control

signal timeout()
signal finished()

@export var tween_trans := Tween.TRANS_CUBIC
@export var label: TypedWord
@export var type := Distraction.Type.EMAIL
@export var effect_root: EffectRoot
@export var timer: Timer

@export var slide_dir := Vector2.ZERO
@export var sounds: Array[AudioStreamPlayer] = []

@onready var start_pos := global_position

var is_open := false
var tw: Tween
var mistakes := 0

func _ready():
	if label:
		label.type_start.connect(func(): GameManager.start_type())
		label.type_finish.connect(func():
			GameManager.finish_type(label.word, mistakes)
			slide_out()
			finished.emit()
		)
		label.type_wrong.connect(func(): mistakes += 1)
	
	if timer:
		timer.timeout.connect(func():
			slide_out()
			timeout.emit()
		)
	
	#hide()
	global_position = get_hide_position()

func set_word(w: String, timeout_sec: int):
	label.word = w
	label.highlight_first = true
	#label.focused = true
	timer.start(timeout_sec)
	slide_in()

func get_word():
	return label.word

func slide_in():
	show()
	slide_in_half()
	#if Input.is_action_pressed("special_mode"):
		#slide_in_full()
	#else:
		#slide_in_half()

func slide_in_half():
	if tw and tw.is_running():
		tw.kill()
	
	var hide_pos = get_hide_position()
	var dir = hide_pos - start_pos
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(tween_trans)
	tw.tween_property(self, "global_position", start_pos + dir/2, 0.5) #.from(get_hide_position())
	tw.finished.connect(func(): if effect_root: effect_root.do_effect())
	
	if not is_open:
		is_open = true
		for s in sounds:
			s.play()
			
			

func slide_in_full():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(tween_trans)
	tw.tween_property(self, "global_position", start_pos, 0.5) #.from(get_hide_position())
	tw.finished.connect(func(): if effect_root: effect_root.do_effect())
	
	if not is_open:
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
	tw.finished.connect(func(): if label: label.reset(""))
	
	if timer:
		timer.stop()
	
	is_open = false
	for s in sounds:
		s.stop()

func get_hide_position():
	return start_pos - slide_dir

func get_label():
	return label
