class_name FeedbackUI
extends MenuPaper

@export var form: TextEdit
@export var limit_label: Label
@export var max_limit := 200

@export var status_label: Label
@export var loading_label: Control

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
		form.editable = not v

var was_sent := false

func _is_open():
	return position == Vector2.ZERO

func _ready() -> void:
	close()
	connect_focus(form)
	_reset()
	
	form.gui_input.connect(func(ev): handle_event(ev))

	FeedbackManager.request_throttled.connect(func(s: float): _show_status("Please wait %.0f s before sending another feedback" % s))
	FeedbackManager.request_running.connect(func(): loading = true)
	FeedbackManager.request_successful.connect(func():
		#_show_status("Thank you for your feedback!") # paper will be send, so this won't be visible anyway
		was_sent = true
		send()
	)
	FeedbackManager.request_failed.connect(func(_err): _show_status("Failed to send feedback. Try again later."))

func _show_status(text: String):
	loading = false
	status_label.text = text
	status_label.show()

func handle_event(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()
		return
	
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed:
			if key_event.shift_pressed and key_event.keycode == KEY_ENTER:
				FeedbackManager.send_feedback(form.text.to_lower())

		var key = KeyReader.get_key_of_event(event)
		if key and has_reached_limit():
			get_viewport().set_input_as_handled()
	
	if form.text.length() > max_limit:
		form.text = form.text.substr(0, max_limit)
	limit_label.text = "%s / %s" % [form.text.length(), max_limit]

func has_reached_limit():
	return form.text.length() >= max_limit

func _reset():
	form.text = ""
	self.loading = false
