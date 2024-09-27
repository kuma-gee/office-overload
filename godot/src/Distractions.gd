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
	"Clarify",
	"Support",
	"Mentorship",
	"Question",
	"Assist",
	"Feedback",
	"Explain",
	"Instruct"
]

enum Type {
	EMAIL,
	PHONE,
	JUNIOR,
}

@onready var delegator = $Delegator
@onready var shake_effect: EffectRoot = $ShakeEffect

@onready var email = $Email
@onready var phone = $Phone
@onready var junior = $Junior
@onready var menus: Array[Control] = [email, phone, junior]

var distraction_accumulator = 0.0

func _ready():
	delegator.nodes = menus
	_close_all()
	show()

func _close_all():
	for x in menus:
		x.hide()

func slide_all_out():
	for x in menus:
		x.slide_out()

func maybe_show_distraction():
	var distraction_random = randf() - distraction_accumulator
	if distraction_random < GameManager.difficulty.distractions:
		show_distraction()
		distraction_accumulator = 0.0
	else:
		# Increase distraction chance, otherwise it's too random and can take too long
		distraction_accumulator += GameManager.difficulty.distractions / 10.

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
	
	var handled = delegator.handle_event(event)
	if event is InputEventKey and not delegator.has_focused() and not handled:
		shake_effect.do_effect(false)

func _has_active_distraction():
	for m in menus:
		if m.is_open:
			return true
	return false
