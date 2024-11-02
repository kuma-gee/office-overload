extends Node2D

signal document_added()

@export var stack_count := 10
@export var max_stacks := 5
@export var combo_multiplier_divider := 5
@export var doc_texture: Texture2D
@export var doc_count_label: Label
@export var combo_label: Label

@export var combo_particles: GPUParticles2D

@onready var cpu_particles_2d = $CPUParticles2D
@onready var cpu_particles_2d_2 = $CPUParticles2D2
@onready var cpu_particles_2d_3 = $CPUParticles2D3
@onready var cpu_particles_2d_4 = $CPUParticles2D4
@onready var particles := [cpu_particles_2d, cpu_particles_2d_2, cpu_particles_2d_3, cpu_particles_2d_4]

var tw: Tween
var total := 0:
	set(v):
		total = v
		doc_count_label.visible = total > 0
		
		if tw and tw.is_running():
			tw.kill()
		tw = create_tween().set_trans(Tween.TRANS_BACK).set_parallel()

		doc_count_label.pivot_offset = doc_count_label.size / 2
		if total == 1:
			doc_count_label.modulate = Color.TRANSPARENT
			tw.tween_property(doc_count_label, "modulate", Color.WHITE, 0.5).set_delay(0.5)
		
		if combo_count == 1:
			combo_label.modulate = Color.TRANSPARENT
			tw.tween_property(combo_label, "modulate", Color.WHITE, 0.5).set_delay(0.5)

		tw.tween_callback(func():
			doc_count_label.text = "%s" % total
			doc_count_label.scale = Vector2(0.6, 0.6)
		).set_delay(0.5)
		tw.tween_property(doc_count_label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_delay(0.5)

var combo_count := 0:
	set(v):
		combo_count = v
		combo_label.visible = combo_count > 1
		#if combo_count <= 1:
			#combo_multiplier = 1
			#combo_particles.emitting = false
		#else:
			#var extra_mult = ceil((combo_count-1) / combo_multiplier_divider)
			#combo_multiplier = 2 + extra_mult
			#combo_label.show()
			#combo_particles.emitting = true
			#combo_particles.speed_scale = 1 + 0.1 * extra_mult

var combo_multiplier := 1:
	set(v):
		combo_multiplier = v
		combo_label.text = "%sx" % combo_multiplier

var perfect_tasks := 0
var tasks := 0

func _ready() -> void:
	total = 0
	combo_count = 0
	combo_multiplier = 2

func _create_doc():
	var sprite = Sprite2D.new()
	sprite.texture = doc_texture
	sprite.scale = Vector2(0.7, 0.7)
	return sprite

func add_document(mistake := false):
	var doc = _create_doc()
	add_child(doc)
	
	var offset = min(floor(total / stack_count), max_stacks - 1)
	var target = Vector2.UP * offset
	
	doc.position = Vector2.RIGHT * 100
	var tw = create_tween()
	tw.tween_property(doc, "position", target + Vector2.UP * 2, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(doc, "position", target, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.1)
	tw.parallel().tween_callback(_emit_particles).set_delay(0.2)
	
	var should_remove = not (total % stack_count == 0 and total <= (max_stacks * stack_count))
	tw.finished.connect(func(): if should_remove: doc.queue_free())
	
	if mistake:
		combo_count = 0
		tasks += 1
	else:
		combo_count += 1
		perfect_tasks += 1
	
	total += 1

func remove_combo():
	combo_label.hide()

func _emit_particles():
	for p in particles:
		p.emitting = true
