class_name Languages
extends FocusedDocument

@export var container: Control
@export var button_scene: PackedScene
@export var max_files := 5

var logger = Logger.new("Languages")
var language := "":
	set(v):
		if not WordManager.is_valid_language(v):
			logger.warn("Invalid language file %s. Changing to default" % v)
			v = WordManager.DEFAULT_WORD_FILE
		
		language = v
		for c in container.get_children():
			c.current_lang = language
		
		if not is_focus_open:
			unfocus()
		

func _ready() -> void:
	super._ready()
	opened.connect(func():
		delegator.focus()
		var l = get_active_lang()
		if l:
			l.get_label().fill_all = false
	)
	closed.connect(func(): unfocus())
	
	create_languages()

func unfocus():
	delegator.unfocus()
	var l = get_active_lang()
	if l:
		l.get_label().fill_all = true

func get_active_lang():
	for c in container.get_children():
		if c.is_active():
			return c
	return null

func create_languages():
	for c in container.get_children():
		c.queue_free()
	
	if Env.is_demo():
		hide()
		return
	
	if not WordManager.available_files.is_empty():
		add_language(WordManager.DEFAULT_WORD_FILE)
	
	for i in range(WordManager.available_files.size()):
		if i >= max_files: break
		
		var file_name = WordManager.available_files[i]
		add_language(file_name)
	
	visible = not WordManager.available_files.is_empty()
	unfocus()

func add_language(file: String):
	var btn = button_scene.instantiate()
	btn.file = file
	btn.typed.connect(func(): language = "" if file == language else file)
	delegator.nodes.append(btn)
	container.add_child(btn)
