class_name DocSpawner
extends Marker2D

@export var document_scene: PackedScene
@export var center_offset := 50
@export var word_generator: WordGenerator
@export var verfical_offset := 0.0
@export var move_back := false
@export_enum(WordManager.WORK_GROUP, WordManager.AFTERWORK_GROUP, WordManager.MEETING_GROUP) var word_type := WordManager.WORK_GROUP

@export var spawn_vertical_offset := 0

var mode = -1
var invalid_word_accum := 0.0
var invalid_spawned := 0
var invalid_skipped := 0
var _logger = Logger.new("DocSpawner")

var word_type_chance := {}

func _ready():
	word_type_chance = {
		WordManager.Type.EASY: GameManager.difficulty.easy_words,
		WordManager.Type.MEDIUM: GameManager.difficulty.medium_words,
		WordManager.Type.HARD: GameManager.difficulty.hard_words,
	}
	
	if word_type == WordManager.WORK_GROUP:
		add_easy()
		if GameManager.day >= 3:
			add_medium()
		elif GameManager.day >= 6:
			add_hard()
	else:
		add_words_from_group()
	
func add_words_from_group():
	var words = WordManager.get_words(word_type)
	word_generator.add_words(words)
	mode = WordManager.Type.ALL

func is_invalid_word(word: String):
	return not word in word_generator.words

func add_easy():
	if mode >= WordManager.Type.EASY: return
	
	var words = WordManager.get_words(WordManager.WORK_GROUP, WordManager.Type.EASY)
	word_generator.add_words(words, WordManager.Type.EASY)
	mode = WordManager.Type.EASY
	
func add_medium():
	if mode >= WordManager.Type.MEDIUM: return
	
	var words = WordManager.get_words(WordManager.WORK_GROUP, WordManager.Type.MEDIUM)
	word_generator.add_words(words, WordManager.Type.MEDIUM)
	mode = WordManager.Type.MEDIUM

func add_hard():
	if mode >= WordManager.Type.HARD or GameManager.is_intern(): return
	
	var words = WordManager.get_words(WordManager.WORK_GROUP, WordManager.Type.HARD)
	word_generator.add_words(words, WordManager.Type.MEDIUM)
	mode = WordManager.Type.HARD

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
	var available = [InvalidType.INVALID]
	if GameManager.days_since_promotion >= 3:
		available.append(InvalidType.SWAP)
	elif GameManager.is_ceo():
		available.append(InvalidType.CENSOR)
	
	for type in invalid_chances.keys():
		if r < invalid_chances[type]:
			return type
		r -= invalid_chances[type]

	return InvalidType.INVALID

func _set_invalid_word(doc: Document, word: String):
	var invalid_type = get_invalid_type()
	match invalid_type:
		InvalidType.INVALID:
			var invalid = WordManager.get_words(WordManager.INVALID_GROUP)
			if invalid.size() > 0:
				word = invalid.pick_random()
			else:
				_logger.warn("No invalid words available")
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
			doc.censored = [randi_range(2, word.length() - 2)]

	doc.word = word

func spawn_invalid_document(type: InvalidType = get_invalid_type()):
	var doc = document_scene.instantiate()
	var word = word_generator.get_random_word()
	if word == "":
		return
	_set_invalid_word(doc, word)

	doc.global_position = global_position
	_move_document_in(doc)
	return doc

func get_word_tag():
	var r = randf()
	var accum = 0.0
	for type in word_type_chance.keys():
		if r <= word_type_chance[type]:
			return type
		accum += word_type_chance[type]
	
	return WordManager.Type.ALL

func spawn_document(invalid_word_chance := 0.0):
	var doc = document_scene.instantiate()
	var word = word_generator.get_random_word(get_word_tag())
	if word == "":
		_logger.warn("No words available for document")
		return null

	if randf() < invalid_word_accum and invalid_skipped > 0:
		_set_invalid_word(doc, word)
		invalid_word_accum = 0.0
		invalid_spawned += 1
		invalid_skipped = 0
	else:
		# after checking, so there won't be two invalid words after another
		invalid_word_accum += invalid_word_chance
		invalid_skipped += 1
		doc.word = word

	_move_document_in(doc)
	return doc

func _move_document_in(doc: Document):
	var y_offset = randf_range(-verfical_offset, verfical_offset)
	doc.global_position = global_position
	doc.global_position.y += spawn_vertical_offset
	doc.global_position.y += y_offset
	
	var x = abs(global_position.x)
	var target = global_position + Vector2.RIGHT * randi_range(x - center_offset, x + center_offset)
	
	add_child(doc)
	move_child(doc, 0)
	doc.move_to(target, true, global_position if move_back else null)
