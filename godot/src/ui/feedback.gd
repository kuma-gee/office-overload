class_name FeedbackUI
extends Control

signal closed()

@export var label: TextEdit
@export var limit_label: Label
@export var max_limit := 200

@export var status_label: Label
@export var loading_label: Label

@onready var effect_root: EffectRoot = $EffectRoot

const KEY_MAPS = {
	KEY_ENTER: "\n",
	KEY_TAB: "\t",
	KEY_SPACE: " ",
	KEY_PERIOD: ".",
	KEY_COMMA: ",",
	KEY_SLASH: "/",
}

var loading := false:
	set(v):
		loading = v
		loading_label.visible = v
		status_label.hide()
		label.editable = not v

var was_sent := false

func _is_open():
	return position == Vector2.ZERO

func _ready() -> void:
	_reset()
	
	label.focus_entered.connect(func():
		if not _is_open():
			effect_root.do_effect()
	)
	label.focus_exited.connect(func():
		if _is_open():
			effect_root.reverse_effect()
	)
	label.gui_input.connect(func(ev): handle_event(ev))
	closed.connect(func(): get_viewport().gui_release_focus())

	FeedbackManager.request_throttled.connect(func(s: float): _show_status("Please wait %.0f s before sending another feedback" % s))
	FeedbackManager.request_running.connect(func(): loading = true)
	FeedbackManager.request_successful.connect(func():
		_show_status("Thank you for your feedback!")
		was_sent = true
	)
	FeedbackManager.request_failed.connect(func(): _show_status("Failed to send feedback. Try again later."))

func _show_status(text: String):
	loading = false
	status_label.text = text
	status_label.show()

func handle_event(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()
		return
	
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed:
			if key_event.shift_pressed and key_event.keycode == KEY_ENTER:
				FeedbackManager.send_feedback(label.text.to_lower())

	limit_label.text = "%s / %s" % [label.text.length(), max_limit]
	if label.text.length() >= max_limit:
		label.text = label.text.substr(0, max_limit)
		get_viewport().set_input_as_handled()

func open():
	if was_sent:
		_reset()
	
	show()
	label.grab_focus()

func _reset():
	label.text = ""
	self.loading = false
