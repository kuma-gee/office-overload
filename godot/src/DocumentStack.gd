extends Node2D

signal document_added()

@export var stack_count := 10
@export var max_stacks := 5

@onready var cpu_particles_2d = $CPUParticles2D
@onready var cpu_particles_2d_2 = $CPUParticles2D2
@onready var cpu_particles_2d_3 = $CPUParticles2D3
@onready var cpu_particles_2d_4 = $CPUParticles2D4
@onready var particles := [cpu_particles_2d, cpu_particles_2d_2, cpu_particles_2d_3, cpu_particles_2d_4]

const DOC = preload("res://assets/Document.png")

var total := 0

func _create_doc():
	var sprite = Sprite2D.new()
	sprite.texture = DOC
	sprite.scale = Vector2(0.7, 0.7)
	return sprite

func add_document():
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
	total += 1

func _emit_particles():
	for p in particles:
		p.emitting = true
