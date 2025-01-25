class_name DocSpawner
extends Marker2D

@export var document_scene: PackedScene
@export var word_generator: WordGenerator
@export var spill_mug: SpillMug
@export var center_offset := 50
@export var verfical_offset := 0.0
@export var move_back := false

@export_enum(WordManager.WORK_GROUP, WordManager.AFTERWORK_GROUP, WordManager.MEETING_GROUP) var word_type := WordManager.WORK_GROUP

@export var spawn_vertical_offset := 0
@export var positions: Array[Node2D] = []

var mode = -1
var invalid_word_accum := 0.0
var invalid_spawned := 0
var invalid_skipped := 0
var _logger = Logger.new("DocSpawner")

var last_position: Node2D
var word_type_chance := {}

func _ready():
	if word_type == WordManager.WORK_GROUP and GameManager.is_work_mode():
		word_type_chance = {
			WordManager.Type.EASY: GameManager.difficulty.easy_words,
			WordManager.Type.MEDIUM: GameManager.difficulty.medium_words,
			WordManager.Type.HARD: GameManager.difficulty.hard_words,
		}

		add_easy()
		
		if GameManager.is_intern() and GameManager.get_performance_within_level() >= 5:
			add_medium()
		elif not GameManager.is_intern():
			add_medium()
		
		if GameManager.is_junior() and GameManager.get_performance_within_level() >= 6:
			add_hard()
		elif not GameManager.is_intern() and not GameManager.is_junior():
			add_hard()
		
	else:
		add_words_from_group()
		set_difficulty(0.0)

func set_difficulty(v: float):
	if v < 0.1:
		word_type_chance = {WordManager.Type.EASY: 1.0, WordManager.Type.MEDIUM: 0.0, WordManager.Type.HARD: 0.0, }
	elif v < 0.3:
		word_type_chance = {WordManager.Type.EASY: 0.7, WordManager.Type.MEDIUM: 0.3, WordManager.Type.HARD: 0.0, }
	elif v < 0.6:
		word_type_chance = {WordManager.Type.EASY: 0.4, WordManager.Type.MEDIUM: 0.5, WordManager.Type.HARD: 0.1, }
	elif v < 0.9:
		word_type_chance = {WordManager.Type.EASY: 0.2, WordManager.Type.MEDIUM: 0.5, WordManager.Type.HARD: 0.3, }
	elif v <= 1.3:
		word_type_chance = {WordManager.Type.EASY: 0.1, WordManager.Type.MEDIUM: 0.4, WordManager.Type.HARD: 0.5, }
	else:
		word_type_chance = {WordManager.Type.EASY: 0.0, WordManager.Type.MEDIUM: 0.3, WordManager.Type.HARD: 0.7, }
	
func add_words_from_group():
	for type in [WordManager.Type.EASY, WordManager.Type.MEDIUM, WordManager.Type.HARD]:
		var words = WordManager.get_words(word_type, type)
		word_generator.add_words(words, type)
	
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
	word_generator.add_words(words, WordManager.Type.HARD)
	mode = WordManager.Type.HARD

enum InvalidType {
	INVALID,
	SWAP,
}

var invalid_chances = {
	InvalidType.INVALID: 0.5,
	InvalidType.SWAP: 0.3,
}

func get_invalid_type():
	var available = [InvalidType.INVALID]
	if GameManager.get_performance_within_level() >= 5 or (GameManager.is_ceo() and not spill_mug.active):
		available.append(InvalidType.SWAP)
	
	var r = randf()
	for type in available:
		if r < invalid_chances[type]:
			return type
		r -= invalid_chances[type]

	return InvalidType.INVALID

func _set_invalid_word(doc: Document, word: String, invalid_type = get_invalid_type()):
	var original_word = word
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

	doc.word = word

func spawn_boss_document(invalid_word_chance := 0.0):
	return spawn_document(invalid_word_chance, WordManager.Type.HARD, InvalidType.INVALID)

func get_word_tag():
	var r = randf()
	var accum = 0.0
	for type in word_type_chance.keys():
		accum += word_type_chance[type]
		
		if r <= accum:
			return type
	
	return WordManager.Type.ALL

func spawn_document(invalid_word_chance := 0.0, tag = get_word_tag(), invalid_type = get_invalid_type()):
	var doc = document_scene.instantiate()
	var word = word_generator.get_random_word(tag)
	if word == "":
		_logger.warn("No words available for document")
		return null
	
	doc.original_word = word
	if randf() < invalid_word_accum and invalid_skipped > 0:
		_set_invalid_word(doc, word, invalid_type)
		invalid_word_accum = 0.0
		invalid_spawned += 1
		invalid_skipped = 0
	else:
		# after checking, so there won't be two invalid words after another
		var mult = remap(GameManager.performance, GameManager.get_min_performance(), GameManager.get_max_performance(), 0.5, 1.5)
		invalid_word_accum += invalid_word_chance * mult
		invalid_skipped += 1
		doc.word = word

	_move_document_in(doc)
	return doc

func _move_document_in(doc: Document):
	var y_offset = randf_range(-verfical_offset, verfical_offset)
	doc.global_position = global_position
	doc.global_position.y += spawn_vertical_offset
	doc.global_position.y += y_offset
	
	var target = _get_target_position()
	
	add_child(doc)
	move_child(doc, 0)
	doc.move_to(target, true, global_position if move_back else null)

func _get_target_position():
	if positions.is_empty():
		var x = abs(global_position.x)
		return global_position + Vector2.RIGHT * randi_range(x - center_offset, x + center_offset)
	
	var node = positions.filter(func(p): return p != last_position).pick_random()
	last_position = node
	
	var pos = node.global_position
	pos.x += randi_range(-center_offset, center_offset)
	return pos
