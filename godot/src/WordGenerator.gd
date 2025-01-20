class_name WordGenerator
extends Node

@export var words := []
@export var last_words_size := 5

var last_words := []
var tagged_words = {}

func add_words(new_words: Array, tag = null):
	for w in _normalize(new_words):
		if not w in self.words:
			self.words.append(w)
	
	if tag != null:
		tagged_words[tag] = new_words
	
	print(tag, new_words)

func remove_words_less(char_count: int):
	for w in words:
		if w.length() < char_count:
			words.erase(w)

func _normalize(words: Array):
	var result = []
	for w in words:
		result.append(w.replace(" ", "").to_lower())
	return result

func get_random_word(tag = null):
	var arr = []
	if tag != null and tag in tagged_words:
		arr.append_array(tagged_words[tag])
	elif not words.is_empty():
		arr.append_array(words)

	if arr.is_empty():
		return ""

	var word = arr.pick_random()
	while word in last_words:
		word = arr.pick_random()
	
	if last_words.size() >= last_words_size:
		last_words.pop_front()
	last_words.append(word)

	return word
