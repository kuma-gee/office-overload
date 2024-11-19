extends Node

const WORD_FILE := "res://assets/theme/words.csv"

const WORK_GROUP = "WORK"
const AFTERWORK_GROUP = "AFTERWORK"
const INVALID_GROUP = "INVALID"
const MEETING_GROUP = "MEETING"

enum Type {
	EASY,
	MEDIUM,
	HARD,
	ALL,
}

@export var medium_word_length := 6
@export var hard_word_length := 9

var all_words := {}

func _ready():
	var file = FileAccess.open(WORD_FILE, FileAccess.READ)
	if not file:
		print("Failed to open file %s" % WORD_FILE)
		return
	
	var words = file.get_as_text().split("\n")
	file.close()

	for line in words:
		var parts = line.split(";")
		if parts.size() != 2:
			continue

		var group = parts[1]
		if not group in all_words:
			all_words[group] = []
		
		var word = parts[0].strip_edges().to_lower()
		if not word in all_words[group]:
			all_words[group].append(word)
		else:
			print("Duplicate word %s in group %s" % [word, group])
	
	for x in all_words:
		print("Added %d words to group %s" % [all_words[x].size(), x])

func get_words(group: String, type: Type = Type.ALL) -> Array:
	if not group in all_words:
		return []
	
	var words = all_words[group]
	if type == Type.EASY:
		return words.filter(func(w): return w.length() < medium_word_length)
	elif type == Type.MEDIUM:
		return words.filter(func(w): return w.length() >= medium_word_length)
	elif type == Type.HARD:
		return words.filter(func(w): return w.length() >= hard_word_length)

	return words
