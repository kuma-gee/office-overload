extends FocusedDocument

@export var container: Control
@export var button_scene: PackedScene
@export var max_files := 5

func _ready() -> void:
	super._ready()
	opened.connect(func():
		delegator.focus()
		var l = get_active_lang()
		if l:
			l.get_label().fill_all = false
	)
	closed.connect(func(): unfocus())
	
	update_languages()

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

func update_languages():
	for c in container.get_children():
		c.queue_free()
	
	if not WordManager.available_files.is_empty():
		add_language(WordManager.DEFAULT_WORD_FILE)
	
	for i in range(WordManager.available_files.size()):
		if i >= max_files: break
		
		var file_name = WordManager.available_files[i]
		add_language(file_name)
	
	visible = not WordManager.available_files.is_empty() and not Env.is_demo()
	unfocus()

func add_language(file: String):
	var btn = button_scene.instantiate()
	btn.file = file
	delegator.nodes.append(btn)
	container.add_child(btn)
