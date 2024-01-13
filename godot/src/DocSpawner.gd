extends Marker2D

const WORDS = [
	"desk",
	"computer",
	"meeting",
	"project",
	"deadline",
	"email",
	"colleague",
	"manager",
	"office",
	"workspace",
	"overtime",
	"presentation",
	"task",
	"report",
	"conference",
	"break",
	"coffee",
	"copier",
	"printer",
	"document",
	"file",
	"folder",
	"teamwork",
	"collaboration",
	"workplace",
	"promotion",
	"commute",
	"client",
	"business",
	"employee",
	"boss",
	"intern",
	"laptop",
	"meeting room",
	"office supplies",
	"salary",
	"benefits",
	"vacation",
	"deadline",
	"stress",
	"workload",
	"office culture",
	"telecommute",
	"office politics",
	"worklife balance",
	"office space",
	"company policy",
	"overload",
]

@export var document_scene: PackedScene
@export var center_offset := 50

var last_words := []

func spawn_document():
	var word = WORDS.pick_random()
	while word in last_words:
		word = WORDS.pick_random()
	
	var doc = document_scene.instantiate()
	doc.word = word
	doc.global_position = global_position
	
	var x = abs(global_position.x)
	var target = global_position + Vector2.RIGHT * randi_range(x - center_offset, x + center_offset)
	add_child(doc)
	move_child(doc, 0)
	doc.move_to(target, true)
	
	if last_words.size() > 5:
		last_words.pop_front()
	last_words.append(word)
	
	return doc
