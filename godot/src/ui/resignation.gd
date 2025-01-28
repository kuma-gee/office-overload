extends MenuPaper

@export var signature: TypedWord
@export var text: RichTextLabel
@export var max_length := 20

func _ready() -> void:
	super._ready()
	
	visible = GameManager.has_current_job()
	text.text = text.text % GameManager.get_level_text()
	signature.type_finish.connect(func():
		GameManager.reset_values()
		send()
	)

	focus_entered.connect(func(): _update_sign())
	_update_sign()


func _update_sign():
	if SteamManager.is_steam_available():
		signature.word = SteamManager.get_username()
		if signature.word.length() > max_length:
			signature.word = signature.word.substr(0, max_length) + "..."
	else:
		signature.word = "Anonymous"
