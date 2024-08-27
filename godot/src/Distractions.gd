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

@onready var delegator = $Delegator

@onready var email = $Email
@onready var phone = $Phone
@onready var junior = $Junior
@onready var menus := [email, phone, junior]

func _ready():
	_close_all()

func _close_all():
	for x in menus:
		x.hide()

func slide_all_out():
	for x in menus:
		x.slide_out()

func show_distraction():
	var available = menus.filter(func(m): return m.get_word() == "")
	if not GameManager.is_senior():
		available.erase(junior)
	
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
	delegator.handle_event(event)

func _has_active_distraction():
	for m in menus:
		if m.get_label().word != "":
			return true
	return false
