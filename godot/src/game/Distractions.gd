class_name Distraction
extends Control

signal distraction_shown()

enum Type {
	EMAIL,
	PHONE,
	JUNIOR,
}

@export var overlay: Control
@export var work_time: WorkTime

@onready var delegator = $Delegator
@onready var shake_effect: EffectRoot = $ShakeEffect
@onready var email_words: WordGenerator = $EmailWords
@onready var phone_words: WordGenerator = $PhoneWords
@onready var junior_words: WordGenerator = $JuniorWords

@onready var TYPE_MAP = {
	Type.EMAIL: email_words,
	Type.PHONE: phone_words,
	Type.JUNIOR: junior_words,
}

@onready var email = $Email
@onready var phone = $Phone
@onready var junior = $Junior
@onready var menus: Array[Node] = [email, phone, junior]

var _logger = Logger.new("Distraction")

var tw: Tween
var distraction_accumulator = 0.0
#var missed := 0
var last_menu = null

var shown := 0
var skipped_since_last_distraction := 0

# Min range: 1 - 2
# Max range: 8 - 10
@onready var min_count = clamp(remap(GameManager.performance, GameManager.get_min_performance(), GameManager.get_max_performance() * 0.7, 1, 8), 1, 8) if GameManager.is_senior() else 5
@onready var max_count = min_count + (1 if min_count < 3 else 2)

func _ready():
	_logger.info("Performance: %s, within %s, left: %s" % [GameManager.performance, GameManager.get_performance_within_level(), GameManager.get_until_max_performance()])

	email_words.add_words(WordManager.get_words(WordManager.EMAIL_GROUP))
	phone_words.add_words(WordManager.get_words(WordManager.PHONE_GROUP))
	junior_words.add_words(WordManager.get_words(WordManager.JUNIOR_GROUP))
	
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
		#m.timeout.connect(func(): missed += 1)

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
		_logger.debug("Max distractions shown, not showing more")
		return

	var distractions_left_to_show = min_count - shown
	_logger.debug("%s distractions left to show: %s" % [distractions_left_to_show, distraction_accumulator])

	var skip_count = [4, 3, 2, 2, 1, 0, 0, 0, 0] if GameManager.get_performance_within_level() == 0 else [3, 2, 2, 1, 1, 0, 0, 0, 0]
	var distraction_random = randf() - distraction_accumulator
	var chance = GameManager.difficulty.distractions * GameManager.get_distraction_reduction()
	if distraction_random < chance and skipped_since_last_distraction >= skip_count[min(shown, skip_count.size() - 1)]:
		show_distraction()
		distraction_accumulator = 0.0
		skipped_since_last_distraction = 0
	else:
		# Increase distraction chance, otherwise it's too random and can take too long
		distraction_accumulator += (GameManager.difficulty.distractions / 10.0) * distractions_left_to_show
		skipped_since_last_distraction += 1

func show_distraction():
	var available = menus.filter(func(m): return not m.is_open and (m != last_menu or randf() > 0.7))
	if not GameManager.is_senior():
		available.erase(junior)
	
	_logger.debug("Showing distraction: %s, %s" % [available, menus.map(func(x): return x.get_word())])
	if available.is_empty(): return
	shown += 1
	
	var distraction = available.pick_random()
	last_menu = distraction
	
	var word = _get_random_distraction_word(distraction.type)
	if word:
		distraction.set_word(word)
		_show_overlay()
		distraction_shown.emit()
	
func _get_random_distraction_word(type: Type):
	var gen = TYPE_MAP[type]
	return gen.get_random_word()

func get_active_words():
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
	
func _show_overlay():
	if tw and tw.is_running() or overlay.modulate == Color.WHITE:
		print("Is already running: %s, or active %s" % [tw.is_running(), overlay.modulate])
		return
	
	print("Show overlay")
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "modulate", Color.WHITE, 0.5)
	overlay.show()
	
	for m in menus:
		if m.is_open:
			m.slide_in_full()
	
func _input(event):
	if not event is InputEventKey: return
	if not _has_active_distraction(): return
	
	var handled = delegator.handle_event(event)
	if event is InputEventKey and not delegator.has_focused() and not handled:
		shake_effect.do_effect(false)

func _has_active_distraction():
	for m in menus:
		if m.is_open:
			return true
	return false
