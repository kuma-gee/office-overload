@tool
extends Control

@export var run := false:
	set(v):
		do_run()

@export var color: Color
@export var distance_x := 3
@export var count := 0
@export var rect_size := Vector2(3, 3)

func _ready() -> void:
	for c in get_children():
		c.hide()

func do_run():
	for c in get_children():
		c.queue_free()
	
	for i in range(count):
		var rect = ColorRect.new()
		rect.color = color
		rect.size = rect_size
		rect.position.x = i * distance_x
		add_child(rect)
		rect.owner = owner
