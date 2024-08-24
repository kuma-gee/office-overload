class_name Distraction
extends Control

const EMAIL = [
	"Greetings",
	"Meeting",
	"Schedule",
	"Urgent",
	"Attachment",
	"Reminder",
	"Deadline",
	"Confirmation",
	"Response"
]

const PHONE = [
	"Voicemail",
	"Reception",
	"Hold",
	"Speaker",
	"Mute",
	"Ring",
	"Decline",
	"Ignore",
	"Answer",
]

const JUNIOR = [
	"Guidance",
	"Advice",
	"Clarification",
	"Support",
	"Mentorship",
	"Question",
	"Assistance",
	"Feedback",
	"Explanation",
	"Instruction"
]

enum Type {
	EMAIL,
	PHONE,
	JUNIOR,
}

@onready var email = $Email
@onready var phone = $Phone
@onready var junior = $Junior
@onready var menus := [email, phone, junior]

func _ready():
	_close_all()

func _close_all():
	for x in menus:
		x.hide()

func show_distraction():
	var available = menus.filter(func(m): return m.get_word() == "")
	if available.is_empty(): return
	
	var distraction = available.pick_random()
	var word = _get_random_distraction_word(distraction.type)
	distraction.set_word(word)

func _get_random_distraction_word(type: Type):
	match type:
		Type.EMAIL: return EMAIL.pick_random()
		Type.PHONE: return PHONE.pick_random()
		Type.JUNIOR: return JUNIOR.pick_random()

	return ""

func _input(event):
	if not _has_active_distraction(): return
	
	if event.is_action_pressed("ui_cancel"):
		for m in menus:
			m.label.reset()
		return
	
	var key = KeyReader.get_key_of_event(event)
	if key:
		var focusd = _get_focused_label()
		if focusd:
			focusd.handle_key(key)
		else:
			var first = _get_first_label_starting(key)
			if first:
				first.handle_key(key)
	
	get_viewport().set_input_as_handled()

func _has_active_distraction():
	for m in menus:
		if m.get_word() != "":
			return true
	return false

func _get_first_label_starting(key: String):
	for m in menus:
		var word = m.get_word()
		if word != "" and word.begins_with(key):
			return m.label
	return null

func _get_focused_label():
	for m in menus:
		if m.get_word() != "" and m.label.focused:
			return m.label
	return null
