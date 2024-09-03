class_name WordGenerator
extends Node

@export var words := []
@export var last_words_size := 5

var last_words := []

func add_words(words: Array):
	self.words.append_array(_normalize(words))

func remove_words_less(char_count: int):
	for w in words:
		if w.length() < char_count:
			words.erase(w)

func _normalize(words: Array):
	var result = []
	for w in words:
		result.append(w.replace(" ", "").to_lower())
	return result

func get_random_word():
	var word = words.pick_random()
	while word in last_words:
		word = words.pick_random()
	
	if last_words.size() >= last_words_size:
		last_words.pop_front()
	last_words.append(word)

	return word
