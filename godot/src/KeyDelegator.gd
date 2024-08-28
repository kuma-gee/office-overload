class_name KeyDelegator
extends Node

signal finished(typed_word)

@export var key_reader: KeyReader

var current_nodes := []
var typed := ""

func _ready():
	if current_nodes.is_empty():
		current_nodes = get_children()
		
	#for node in current_nodes:
		#if node is TypingButton:
			#node.finished.connect(func(): cancel())
		
	if key_reader:
		key_reader.pressed_key.connect(func(key, _s): handle_key(key))
		key_reader.pressed_cancel.connect(func(_s): cancel())

func handle_key(key: String):
	var word = typed + key
	var matches = _get_nodes_starting_with(current_nodes, word)
	#print("Typed: %s, Matches: %s, From: %s" % [word, matches, current_nodes])

	if matches.is_empty():
		cancel()
		return
	
	typed = word
	SoundManager.play_type_sound()
	_update_typed()

func _update_typed():
	var found := false
	for node in current_nodes:
		if node.has_method("set_typed"):
			node.set_typed(typed)

func _get_nodes_starting_with(nd: Array, text: String) -> Array:
	return nd.filter(func(n): return is_instance_valid(n) and n.has_method("get_word") and n.get_word().begins_with(text))

func cancel():
	for node in current_nodes:
		if node.has_method("set_typed"):
			node.set_typed("")
	
	typed = ""
