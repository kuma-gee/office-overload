class_name DocSpawner
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
var invalid_spawned := 0

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
	#return word in INVALID_WORDS
	return not word in word_generator.words

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

enum InvalidType {
	INVALID,
	SWAP,
	CENSOR,
}

var invalid_chances = {
	InvalidType.INVALID: 0.5,
	InvalidType.SWAP: 0.3,
	InvalidType.CENSOR: 0.2,
}

func get_invalid_type():
	var r = randf()
	for type in invalid_chances.keys():
		if r < invalid_chances[type]:
			return type
		r -= invalid_chances[type]

	return InvalidType.INVALID

func _set_invalid_word(doc: Document, word: String):
	var invalid_type = get_invalid_type()
	match invalid_type:
		InvalidType.INVALID:
			word = INVALID_WORDS.pick_random()
		InvalidType.SWAP:
			for _x in randi_range(2, 5):
				var swap_idx = randi_range(1, word.length() - 1)
				
				if randf() < 0.3:
					word.erase(swap_idx)
				else:
					var target_idx = swap_idx
					while target_idx == swap_idx:
						target_idx = randi_range(1, word.length() - 1)

					var temp = word[target_idx]
					word[target_idx] = word[swap_idx]
					word[swap_idx] = temp
		InvalidType.CENSOR:
			# Words should be at least 4 characters long
			doc.censored = [word[randi_range(2, word.length() - 2)]]

	doc.word = word

func spawn_invalid_documents(type: InvalidType, count: int):
	var docs = []
	for _x in count:
		var doc = document_scene.instantiate()
		_set_invalid_word(doc, word_generator.get_random_word())
		doc.global_position = global_position
		_move_document_in(doc)
		docs.append(doc)
	return docs

func spawn_document(invalid_word_chance := 0.0):
	var doc = document_scene.instantiate()
	var word = word_generator.get_random_word()

	if randf() < invalid_word_accum:
		_set_invalid_word(doc, word)
		invalid_word_accum = 0.0
		invalid_spawned += 1
	else:
		# after checking, so there won't be two invalid words after another
		invalid_word_accum += invalid_word_chance
		doc.word = word

	_move_document_in(doc)
	return doc

func _move_document_in(doc: Document):
	doc.global_position = global_position
	
	var x = abs(global_position.x)
	var target = global_position + Vector2.RIGHT * randi_range(x - center_offset, x + center_offset)
	add_child(doc)
	move_child(doc, 0)
	doc.move_to(target, _get_rotation(), true)
