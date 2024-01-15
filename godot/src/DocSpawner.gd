extends Marker2D

const EASY = [
	"chair",
	"phone",
	"mouse",
	"plant",
	"light",
	"pen",
	"table",
	"lamp",
	"desk",
	"drawer",
	"email",
	"break",
	"coffee",
	"task",
	"report",
	"file",
	"copier",
	"printer",
	"folder",
	"boss",
	"intern",
	"commute",
	"client",
	"office",
	"stress",
]
const MEDIUM = [
	"manager",
	"document",
	"notebook",
	"computer",
	"meeting",
	"project",
	"deadline",
	"colleague",
	"workspace",
	"overtime",
	"conference",
	"teamwork",
	"workplace",
	"promotion",
	"business",
	"employee",
	"benefits",
	"vacation",
	"deadline",
	"workload",
	"overload",
]
const HARD = [
	"presentation",
	"collaboration",
	"meeting room",
	"office supplies",
	"telecommute",
	"office culture",
	"office politics",
	"worklife balance",
	"office space",
	"company policy",
	"productivity",
	"motivation",
	"negotiation",
	"organization",
	"professional",
]

enum Mode {
	EASY,
	MEDIUM,
	HARD,
}

@export var document_scene: PackedScene
@export var center_offset := 50

var mode = Mode.EASY
var words := []
var last_words := []

func _ready():
	add_easy()

func add_easy():
	words.append_array(_normalize(EASY))
	mode = Mode.EASY
	
func add_medium():
	_remove_less_than(6)
	words.append_array(_normalize(MEDIUM))
	mode = Mode.MEDIUM

func add_hard():
	_remove_less_than(9)
	words.append_array(_normalize(HARD))
	mode = Mode.HARD

func _remove_less_than(char_count: int):
	for w in words:
		if w.length() < char_count:
			words.erase(w)

func _normalize(words: Array):
	var result = []
	for w in words:
		result.append(w.replace(" ", "").to_lower())
	return result

func _get_rotation():
	match mode:
		Mode.EASY: return PI/12
		Mode.MEDIUM: return PI/8
		Mode.HARD: return PI/6
	return PI

func spawn_document():
	var word = words.pick_random()
	while word in last_words:
		word = words.pick_random()
	
	var doc = document_scene.instantiate()
	doc.word = word
	doc.global_position = global_position
	
	var x = abs(global_position.x)
	var target = global_position + Vector2.RIGHT * randi_range(x - center_offset, x + center_offset)
	add_child(doc)
	move_child(doc, 0)
	doc.move_to(target, true, _get_rotation())
	
	if last_words.size() > 5:
		last_words.pop_front()
	last_words.append(word)
	
	return doc
