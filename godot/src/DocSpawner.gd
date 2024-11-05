extends Marker2D

const EASY = [
	"chair",
	"phone",
	"mouse",
	"plant",
	"light",
	"pencil",
	"table",
	"lamp",
	"desk",
	"drawer",
	"email",
	"break",
	"coffee",
	"tasks",
	"report",
	"files",
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
	"multitasking",
	"telecommute",
	"brainstorming",
	"office space",
	"micromanagement",
	"stakeholder",
	"entrepreneurship",
	"productivity",
	"motivation",
	"negotiation",
	"organization",
	"professional",
	"performance",
	"communication",
	"optimization",
]

const INVALID_WORDS = [
	"tomato",
	"potato",
	"carrot",
	"cucumber",
	"lettuce",
	"broccoli",
	"onion",
	"garlic",
	"pineapple",
	"watermelon",
	"applepie",
	"brownie",
	"cookie",
	"muffin",
	"donut",
	"croissant",
	"baguette",
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
var invalid_word_accum := 0.0

func _ready():
	if GameManager.is_work_mode():
		var p = clamp(GameManager.day / 10, 0, 1)
		if GameManager.is_intern():
			add_easy()
			if GameManager.day >= 4 and p > 0.8:
				add_medium()
		else:
			if GameManager.is_junior():
				add_easy()
				if p > 0.4:
					add_medium()
				if p > 0.9:
					add_hard()
			else:
				add_medium()
				if p > 0.9:
					add_hard()

	elif GameManager.is_interview_mode():
		add_easy()
		add_medium()
	elif GameManager.is_crunch_mode():
		add_easy()

func is_invalid_word(word: String):
	return word in INVALID_WORDS

func add_easy():
	if mode >= Mode.EASY: return
	
	word_generator.add_words(EASY)
	mode = Mode.EASY
	
func add_medium():
	if mode >= Mode.MEDIUM: return
	
	#word_generator.remove_words_less(6)
	word_generator.add_words(MEDIUM)
	mode = Mode.MEDIUM

func add_hard():
	if mode >= Mode.HARD or GameManager.is_intern(): return
	
	#word_generator.remove_words_less(9)
	word_generator.add_words(HARD)
	mode = Mode.HARD

func _get_rotation():
	# match mode:
		# Mode.EASY: return PI/20
		#Mode.MEDIUM: return PI/10
		#Mode.HARD: return PI/8
	return PI/20

func spawn_document(invalid_word_chance := 0.0):
	var doc = document_scene.instantiate()

	invalid_word_accum += invalid_word_chance
	if randf() < invalid_word_accum:
		doc.word = INVALID_WORDS.pick_random()
		invalid_word_accum = 0.0
	else:
		doc.word = word_generator.get_random_word()

	doc.global_position = global_position
	
	var x = abs(global_position.x)
	var target = global_position + Vector2.RIGHT * randi_range(x - center_offset, x + center_offset)
	add_child(doc)
	move_child(doc, 0)
	doc.move_to(target, _get_rotation(), true)
	
	return doc
