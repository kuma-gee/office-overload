extends Node2D

@onready var doc_spawner = $DocSpawner

var documents = []

func _ready():
	_spawn()

func _spawn():
	var doc = doc_spawner.spawn_document()
	doc.finished.connect(func():
		doc.move_to(Vector2(-doc_spawner.global_position.x, doc_spawner.global_position.y))
		documents.erase(doc)
	)
	documents.append(doc)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not documents.is_empty():
		var text = event.as_text()
		if text.length() != 1:
			return
		
		documents[0].handle_key(text)
		
