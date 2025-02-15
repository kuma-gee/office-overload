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

@export var max_file_length := 18
@export var min_group_size := 10

var all_words := {}
var _logger = Logger.new("WordManager")
var available_files = []

func _ready():
	var all_files = DataLoader.list_csv_files(DEFAULT_FOLDER)
	for file in all_files:
		if file == DEFAULT_WORD_FILE + ".csv": continue
		var lang = file.split(".")[0]
		if lang.length() > max_file_length:
			_logger.warn("Skipping language file %s because it's too long" % lang)
			continue

		if is_valid_language_file(lang):
			available_files.append(lang)
	
	_logger.info("Loaded local language files: %s" % [available_files])

func is_valid_language_file(file: String):
	var lines = DataLoader.load_csv(_build_path(file), ["word", "group"])
	var counts := {}
	var work_words := []
	for line in lines:
		var group = line["group"]
		if not group in counts:
			counts[group] = 0
		
		counts[group] += 1
		if group == WORK_GROUP:
			work_words.append(line["word"])
	
	for group in VALID_GROUPS:
		if not group in counts:
			_logger.warn("Group %s is missing in file %s" % [group, file])
			return false
		elif counts[group] < min_group_size:
			_logger.warn("Group %s has less than %d words in file %s: %s" % [group, min_group_size, file, counts[group]])
			return false

		if group == WORK_GROUP:
			var grouped = group_words(work_words)
			for type in grouped:
				if grouped[type].size() < min_group_size:
					_logger.warn("Group %s has less than %d %s words in file %s: %s" % [group, min_group_size, Type.keys()[type], file, grouped[type].size()])
					return false

	return true

func _build_path(file: String):
	return DEFAULT_FOLDER + "/" + file + ".csv"

func is_valid_language(lang: String):
	return lang in available_files or lang == DEFAULT_WORD_FILE

func load_words(file: String):
	if not is_valid_language(file):
		_logger.warn("Language %s does not exist anymore. Using default file %s" % [file, DEFAULT_WORD_FILE])
		file = DEFAULT_WORD_FILE
	
	var grouped_words = {}
	for line in DataLoader.load_csv(_build_path(file), ["word", "group"]):
		var group = line["group"]
		if not group in grouped_words:
			grouped_words[group] = []
		
		var word = line["word"].to_lower()
		if not word in grouped_words[group]:
			grouped_words[group].append(word)
		else:
			_logger.warn("Duplicate word %s in group %s" % [word, group])
	
	all_words = {}
	for group in grouped_words:
		all_words[group] = group_words(grouped_words[group])

	for group in all_words:
		for type in all_words[group]:
			_logger.debug("Added %d words to group %s and type %s" % [all_words[group][type].size(), group, Type.keys()[type]])

func group_words(words: Array):
	var groups = {}
	groups[Type.EASY] = words.filter(func(w): return w.length() < medium_word_length)
	groups[Type.MEDIUM] = words.filter(func(w): return w.length() >= medium_word_length and w.length() < hard_word_length)
	groups[Type.HARD] = words.filter(func(w): return w.length() >= hard_word_length)
	groups[Type.ALL] = words
	
	return groups

func get_words(group: String, type: Type = Type.ALL) -> Array:
	if not group in all_words:
		return []
	
	var words = all_words[group]
	return words[type]
	# if type == Type.EASY:
	# 	return words.filter(func(w): return w.length() < medium_word_length)
	# elif type == Type.MEDIUM:
	# 	return words.filter(func(w): return w.length() >= medium_word_length and w.length() < hard_word_length)
	# elif type == Type.HARD:
	# 	return words.filter(func(w): return w.length() >= hard_word_length)

	# return words
