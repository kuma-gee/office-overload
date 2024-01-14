extends Node2D

@export var stack_count := 10
@export var max_stacks := 5

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
	tw.tween_property(doc, "position", target, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var should_remove = not (total % stack_count == 0 and total <= (max_stacks * stack_count))
	tw.finished.connect(func(): if should_remove: doc.queue_free())
	total += 1
	
