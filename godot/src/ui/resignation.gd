extends MenuPaper

@export var signature: TypedWord
@export var text: RichTextLabel

func _ready() -> void:
	super._ready()
	
	visible = GameManager.has_current_job()
	text.text = text.text % GameManager.get_level_text()
	signature.type_finish.connect(func():
		GameManager.reset_values()
		send()
	)
	
	if SteamManager.is_successful_initialized:
		signature.word = SteamManager.get_username()
	else:
		signature.word = "Anonymous"
