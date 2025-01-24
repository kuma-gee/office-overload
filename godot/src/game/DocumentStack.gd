class_name DocumentStack
extends Node2D

signal document_added()
signal document_emptied()

@export var initial_doc_count := 0
@export var stack_count := 10
@export var stack_offset := 1
@export var max_stacks := 5
@export var combo_multiplier_divider := 5
@export var doc_count_label: Label
@export var combo_label: Label
@export var doc_scene: PackedScene

@export var combo_particles01: GPUParticles2D
@export var combo_particles02: GPUParticles2D
@onready var mistake_debounce: Timer = $MistakeDebounce

var tw: Tween
var total_points := 0
var combo_count := 0:
	set(v):
		combo_count = v
		highest_streak = max(combo_count, highest_streak)
		
		if not combo_label: return
		
		combo_label.visible = combo_count > 0
		combo_label.text = "%sx" % combo_count

var tasks := 0
var wrong_tasks := 0:
	set(v):
		if not mistake_debounce.is_stopped(): return
		wrong_tasks = v
		mistake_debounce.start()
		
var highest_streak := 0
var missed_combos := 0

var actual_document_count := 0:
	set(v):
		actual_document_count = v
		if not doc_count_label:
			return
			
		doc_count_label.visible = actual_document_count > 0
		
		if tw and tw.is_running():
			tw.kill()
		tw = create_tween().set_trans(Tween.TRANS_BACK).set_parallel()

		doc_count_label.pivot_offset = doc_count_label.size / 2
		combo_label.pivot_offset = combo_label.size / 2
		
		if actual_document_count == 1:
			doc_count_label.modulate = Color.TRANSPARENT
			tw.tween_property(doc_count_label, "modulate", Color.WHITE, 0.5).set_delay(0.5)
		
		if combo_count == 1:
			combo_label.modulate = Color.TRANSPARENT
			tw.tween_property(combo_label, "modulate", Color.WHITE, 0.5).set_delay(0.5)

		var curr_combo_scale = Vector2.ONE + Vector2(combo_count / 10.0, combo_count / 10.0) if combo_count > 1 else Vector2.ONE
		curr_combo_scale = curr_combo_scale.min(Vector2(2, 2))
		curr_combo_scale = Vector2.ONE
		
		tw.tween_callback(func():
			doc_count_label.text = "%s" % total_points
			doc_count_label.scale = Vector2(0.6, 0.6)
			
			combo_label.scale = curr_combo_scale * 0.8
		).set_delay(0.4)
		tw.tween_property(doc_count_label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_delay(0.5)
		tw.tween_property(combo_label, "scale", curr_combo_scale, 0.5).set_ease(Tween.EASE_OUT).set_delay(0.5)

func _ready() -> void:
	total_points = 0
	combo_count = 0
	actual_document_count = 0
	_init_documents()

func _create_doc(word: String = ""):
	var sprite = doc_scene.instantiate()
	sprite.word = word
	add_child(sprite)
	return sprite

func has_documents():
	return get_child_count() > 0

#func remove_document():
	#actual_document_count -= 1
	#
	#var should_remove = not (actual_document_count % stack_count == 0 and actual_document_count <= (max_stacks * stack_count))
	#if should_remove and get_child_count() > 0:
		#_move_out_doc(get_child(get_child_count() - 1))
		#
	#if actual_document_count <= 0:
		#document_emptied.emit()

func add_document(mistake := 0, wrong := false, is_discarded := false, word := ""):
	if is_discarded:
		return
	
	var doc = _create_doc(" " if wrong else " ".repeat(mistake))
	_move_in_doc(doc)

	if wrong:
		wrong_tasks += 1 #word.length()
		combo_count = 0
		SoundManager.play_type_mistake()
	else:
		tasks += 1
		total_points += 1 + 1 * combo_count
		combo_count += 1

	actual_document_count += 1

func _init_documents():
	for i in range(initial_doc_count):
		var doc = _create_doc()
		doc.position = get_current_final_position()
		actual_document_count += 1

func _move_in_doc(doc):
	var target = get_current_final_position()
	
	doc.position = Vector2.RIGHT * 100
	var tw = create_tween()
	tw.tween_property(doc, "position", target + Vector2.UP * 2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(doc, "position", target, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.1)
	tw.parallel().tween_callback(_emit_particles).set_delay(0.2)
	
	# keep documents for work mode, because it needs to show the number of mistakes
	if GameManager.is_crunch_mode():
		var should_remove = not (actual_document_count % stack_count == 0 and actual_document_count <= (max_stacks * stack_count))
		tw.finished.connect(func(): if should_remove: doc.queue_free())

func _move_out_doc(doc):
	var target = Vector2.LEFT * 100
	var tw = create_tween()
	tw.tween_property(doc, "position", target + Vector2.UP * 2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(doc, "position", target, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.1)
	tw.finished.connect(func():
		if is_instance_valid(doc):
			doc.queue_free()
	)

func get_current_final_position():
	var offset = min(floor(actual_document_count / stack_count), max_stacks - 1)
	return Vector2.UP * offset * stack_offset

func add_combo():
	pass
	#combo_count += 1
	#total += 1 * combo_count % 5

func add_mistake():
	wrong_tasks += 1
	combo_count = 0

func _emit_particles():
	for p in [$CPUParticles2D, $CPUParticles2D2, $CPUParticles2D3, $CPUParticles2D4]:
		p.emitting = true
