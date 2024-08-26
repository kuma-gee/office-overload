class_name WPMCalculator
extends Node

@export var char_in_words := 5.0

var time := -1.0
var wpms = []
var accuracy = []

func get_average_wpm():
	return _get_average(wpms)

func get_average_accuracy():
	return _get_average(accuracy)

func _get_average(arr: Array):
	var result = 0.0
	
	if arr.is_empty():
		return result
	
	for v in arr:
		result += v
	
	return max(result / arr.size(), 0)

func start_type():
	time = 0.0

func cancel_type():
	time = -1.0

func finish_type(word: String, mistakes: int):
	if word.length() == 1 or time <= 0:
		return
	
	var words_count = word.length() / char_in_words
	var minute = time / 60.
	var wpm = words_count / minute
	if wpm > 0:
		wpms.append(wpm)
	
	var total_chars = word.length()
	var correct_chars = float(total_chars) - float(mistakes)
	var acc = correct_chars / float(total_chars)
	accuracy.append(acc)
		
	cancel_type()
	print("Current: %s/%s, Average: %s/%s" % [wpm, acc, get_average_wpm(), get_average_accuracy()])

func _process(delta):
	if time < 0: return
	time += delta
