extends Node

const LOCAL_WORD_FILE := "./words.csv"
const WORD_FILE := "res://words.csv"

const WORK_GROUP = "WORK"
const AFTERWORK_GROUP = "AFTERWORK"
const INVALID_GROUP = "INVALID"
const MEETING_GROUP = "MEETING"

const EMAIL_GROUP = "EMAIL"
const PHONE_GROUP = "PHONE"
const JUNIOR_GROUP = "JUNIOR"

enum Type {
	EASY,
	MEDIUM,
	HARD,
	ALL,
}

@export var medium_word_length := 6
@export var hard_word_length := 9

var all_words := {}
var _logger = Logger.new("WordManager")

func _open_words_file():
	if FileAccess.file_exists(LOCAL_WORD_FILE):
		_logger.info("Loading local word file %s" % LOCAL_WORD_FILE)
		return FileAccess.open(LOCAL_WORD_FILE, FileAccess.READ)
	
	_logger.info("Loading default word file %s" % WORD_FILE)
	return FileAccess.open(WORD_FILE, FileAccess.READ)

func _ready():
	for line in DataLoader.load_csv("words.csv", ["word", "group"]):
		var group = line["group"]
		if not group in all_words:
			all_words[group] = []
		
		var word = line["word"].to_lower()
		if not word in all_words[group]:
			all_words[group].append(word)
		else:
			_logger.warn("Duplicate word %s in group %s" % [word, group])

	for x in all_words:
		_logger.info("Added %d words to group %s" % [all_words[x].size(), x])

func get_words(group: String, type: Type = Type.ALL) -> Array:
	if not group in all_words:
		return []
	
	var words = all_words[group]
	if type == Type.EASY:
		return words.filter(func(w): return w.length() < medium_word_length)
	elif type == Type.MEDIUM:
		return words.filter(func(w): return w.length() >= medium_word_length and w.length() < hard_word_length)
	elif type == Type.HARD:
		return words.filter(func(w): return w.length() >= hard_word_length)

	return words
