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

@export var overlay: Control

@onready var delegator = $Delegator
@onready var shake_effect: EffectRoot = $ShakeEffect

@onready var email = $Email
@onready var phone = $Phone
@onready var junior = $Junior
@onready var menus: Array[Control] = [email, phone, junior]

var tw: Tween
var distraction_accumulator = 0.0
var missed := 0

func _ready():
	overlay.modulate = Color.TRANSPARENT
	delegator.nodes = menus
	_close_all()
	show()
	
	for m in menus:
		m.finished.connect(func():
			if not _has_active_distraction():
				_hide_overlay()
		)
		m.timeout.connect(func(): missed += 1)

func _close_all():
	for x in menus:
		x.hide()

func slide_all_out():
	for x in menus:
		x.slide_out()
	_hide_overlay()

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

func _hide_overlay():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.TRANSPARENT, 0.5)
	
	for m in menus:
		if m.is_open:
			m.slide_in_half()

func _show_overlay():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.WHITE, 0.5)
	
	for m in menus:
		if m.is_open:
			m.slide_in_full()

func _input(event):
	if not event is InputEventKey: return
	
	var key_ev = event as InputEventKey
	if key_ev.is_action_released("special_mode"):
		_hide_overlay()
	
	if not _has_active_distraction(): return
	
	if key_ev.is_action_pressed("special_mode"):
		_show_overlay()
	
	if not Input.is_action_pressed("special_mode"): return
	
	var handled = delegator.handle_event(event)
	if event is InputEventKey and not delegator.has_focused() and not handled:
		shake_effect.do_effect(false)

func _has_active_distraction():
	for m in menus:
		if m.is_open:
			return true
	return false
