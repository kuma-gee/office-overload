class_name TypingSlider
extends HBoxContainer

signal opened(open)

@export var trigger_button: TypingButton
@export var delta := 5
@export var large_delta := 20
@export var left: TypingButton
@export var right: TypingButton
@export var slider: Range

func _ready():
	left.finished.connect(func(): left.get_label().reset())
	right.finished.connect(func(): right.get_label().reset())
	
	trigger_button.finished.connect(func():
		set_control_visible(true)
	)
	set_control_visible(false)

func set_control_visible(v: bool):
	left.visible = v
	right.visible = v
	
	left.get_label().focused = v
	right.get_label().focused = v
	
	var lbl = trigger_button.get_label() as TypedWord
	if v:
		lbl.reset()
		lbl.highlight_first = false
	else:
		lbl.highlight_first = true
	
	slider.highlight(v)
	opened.emit(v)

func handle_event(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		set_control_visible(false)
		return
	
	var key = KeyReader.get_key_of_event(event)
	if key:
		var shift = event.shift_pressed
		
		if left.get_word() == key:
			slider.value -= large_delta if shift else delta
			SoundManager.play_type_sound()
		elif right.get_word() == key:
			slider.value += large_delta if shift else delta
			SoundManager.play_type_sound()