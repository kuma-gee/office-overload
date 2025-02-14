extends Node

const DEFAULT_WORD_FILE := "english"
const DEFAULT_FOLDER := "languages"

const WORK_GROUP = "WORK"
const INVALID_GROUP = "INVALID"
const EMAIL_GROUP = "EMAIL"
const PHONE_GROUP = "PHONE"
const JUNIOR_GROUP = "JUNIOR"

const VALID_GROUPS = [WORK_GROUP, INVALID_GROUP, EMAIL_GROUP, PHONE_GROUP, JUNIOR_GROUP]

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
var available_files = []

func _ready():
	var all_files = DataLoader.list_csv_files(DEFAULT_FOLDER)
	for file in all_files:
		if file == DEFAULT_WORD_FILE + ".csv": continue
		
		var lines = DataLoader.load_csv(DEFAULT_FOLDER + "/" + file, ["word", "group"])
		if not lines.is_empty() and lines[0]["group"] in VALID_GROUPS:
			available_files.append(file.split(".")[0])
	
	_logger.info("Loaded lcoal language files: %s" % [available_files])

func _build_path(file: String):
	return DEFAULT_FOLDER + "/" + file + ".csv"

func load_words(file: String):
	if not file in available_files or file != DEFAULT_WORD_FILE:
		file = DEFAULT_WORD_FILE
	
	for line in DataLoader.load_csv(_build_path(file), ["word", "group"]):
		var group = line["group"]
		if not group in all_words:
			all_words[group] = []
		
		var word = line["word"].to_lower()
		if not word in all_words[group]:
			all_words[group].append(word)
		else:
			_logger.warn("Duplicate word %s in group %s" % [word, group])

	for x in all_words:
		_logger.debug("Added %d words to group %s" % [all_words[x].size(), x])

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
