class_name Distraction
extends Control

enum Type {
	EMAIL,
	PHONE,
	JUNIOR,
}

const TYPE_MAP = {
	Type.EMAIL: WordManager.EMAIL_GROUP,
	Type.PHONE: WordManager.PHONE_GROUP,
	Type.JUNIOR: WordManager.JUNIOR_GROUP,
}

@export var distraction_timeout := 10
@export var overlay: Control
@export var shift_button: DistractionItem
@export var work_time: WorkTime

@onready var delegator = $Delegator
@onready var shake_effect: EffectRoot = $ShakeEffect

@onready var email = $Email
@onready var phone = $Phone
@onready var junior = $Junior
@onready var menus: Array[Node] = [email, phone, junior]

var _logger = Logger.new("Distraction")

var tw: Tween
var distraction_accumulator = 0.0
var missed := 0

var called := 0
var shown := 0
var skipped_since_last_distraction := 0

# Min range: 1 - 2
# Max range: 6 - 8
@onready var min_count = min(GameManager.days_since_promotion + 1, 6)
@onready var max_count = min_count + 1 if min_count < 3 else 2

func _ready():
	_logger.info("Days since promotion: %s" % GameManager.days_since_promotion)
	
	overlay.modulate = Color.TRANSPARENT
	delegator.nodes = menus
	_close_all()
	show()
	
	for m in menus:
		m.finished.connect(func():
			if not _has_active_distraction():
				_hide_overlay()
			delegator.reset()
		)
		m.timeout.connect(func(): missed += 1)

	_logger.info("Showing %s - %s number of distractions today" % [min_count, max_count])

func _close_all():
	for x in menus:
		x.hide()

func slide_all_out():
	for x in menus:
		x.slide_out()
	_hide_overlay()

func maybe_show_distraction():
	if shown >= max_count:
		_logger.info("Max distractions shown, not showing more")
		return

	var distractions_left_to_show = min_count - shown
	_logger.info("%s distractions left to show" % distractions_left_to_show)

	var skip_count = [1, 2, 2, 1, 0, 0, 0, 0, 0]
	var distraction_random = randf() - distraction_accumulator
	if distraction_random < GameManager.difficulty.distractions and skipped_since_last_distraction >= skip_count[shown]:
		show_distraction()
		distraction_accumulator = 0.0
		skipped_since_last_distraction = 0
	else:
		# Increase distraction chance, otherwise it's too random and can take too long
		distraction_accumulator += (GameManager.difficulty.distractions / 10.) * distractions_left_to_show
		skipped_since_last_distraction += 1

func show_distraction():
	var available = menus.filter(func(m): return m.get_word() == "")
	if not GameManager.is_senior():
		available.erase(junior)
	
	if available.is_empty() or GameManager.is_manager(): return
	shown += 1
	
	var distraction = available.pick_random()
	var word = _get_random_distraction_word(distraction.type)
	if word:
		distraction.set_word(word, distraction_timeout)
		_show_overlay()
	
	if not shift_button.is_open:
		shift_button.slide_in_full()

func _get_random_distraction_word(type: Type):
	var group = TYPE_MAP[type]
	var available = WordManager.get_words(group) # TODO: use WordGenerator??
	if available.is_empty():
		_logger.warn("No words available for distraction %s" % group)
		return ""
	return available.pick_random()

func _get_active_words():
	var result = []
	for m in menus:
		if m.is_open:
			result.append(m.get_word())
	return result

func _hide_overlay():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.TRANSPARENT, 0.5)
	
	for m in menus:
		if m.is_open:
			m.slide_in_half()
	
	delegator.reset()
	
	if _has_active_distraction():
		shift_button.slide_in_full()

func _show_overlay():
	if tw and tw.is_running() or overlay.modulate == Color.WHITE:
		return
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.WHITE, 0.5)
	
	for m in menus:
		if m.is_open:
			m.slide_in_full()
	
	shift_button.slide_out()

func _input(event):
	if not event is InputEventKey: return
	
	# var key_ev = event as InputEventKey
	# if key_ev.is_action_released("special_mode"):
	# 	_hide_overlay()
	
	if not _has_active_distraction(): return
	
	# if key_ev.is_action_pressed("special_mode"):
	# 	_show_overlay()
	
	# if not Input.is_action_pressed("special_mode"): return
	
	var handled = delegator.handle_event(event)
	if event is InputEventKey and not delegator.has_focused() and not handled:
		shake_effect.do_effect(false)

func _has_active_distraction():
	for m in menus:
		if m.is_open:
			return true
	return false
