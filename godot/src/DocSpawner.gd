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
@export var word_generator: WordGenerator

var mode = -1

func _ready():
	if GameManager.is_work_mode():
		if GameManager.is_intern():
			add_easy()
		else:
			if GameManager.day >= 5:
				add_hard()
			elif GameManager.day >= 3 or not GameManager.is_junior():
				add_medium()
			else:
				add_easy()
	elif GameManager.is_interview_mode():
		add_easy()
		add_medium()
	elif GameManager.is_crunch_mode():
		add_easy()

func add_easy():
	if mode >= Mode.EASY: return
	
	word_generator.add_words(EASY)
	mode = Mode.EASY
	
func add_medium():
	if mode >= Mode.MEDIUM: return
	
	word_generator.remove_words_less(6)
	word_generator.add_words(MEDIUM)
	mode = Mode.MEDIUM

func add_hard():
	if mode >= Mode.HARD or GameManager.is_intern(): return
	
	word_generator.remove_words_less(9)
	word_generator.add_words(HARD)
	mode = Mode.HARD

func _get_rotation():
	# match mode:
		# Mode.EASY: return PI/20
		#Mode.MEDIUM: return PI/10
		#Mode.HARD: return PI/8
	return PI/20

func spawn_document():
	var word = word_generator.get_random_word()
	var doc = document_scene.instantiate()
	doc.word = word
	doc.global_position = global_position
	
	var x = abs(global_position.x)
	var target = global_position + Vector2.RIGHT * randi_range(x - center_offset, x + center_offset)
	add_child(doc)
	move_child(doc, 0)
	doc.move_to(target, _get_rotation(), true)
	
	return doc
