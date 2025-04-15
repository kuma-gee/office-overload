extends MenuPaper

@export var signature: TypedWord
@export var text: RichTextLabel
@export var max_length := 20

func _ready() -> void:
	super._ready()
	text.text = "Dear %s,\n\nI hereby resign from my position as %s, effective immediately.\n\nPS: you will restart as intern" % ["Me" if GameManager.is_finished_game() else "Boss", GameManager.get_level_text()]
	
	visible = GameManager.has_current_job()
	signature.type_finish.connect(func():
		GameManager.reset_values()
		send()
	)

	focus_entered.connect(func(): _update_sign())
	_update_sign()


func _update_sign():
	if SteamManager.is_steam_available():
		var username = SteamManager.get_username().to_lower()
		signature.word = username if not _contains_special_characters(username) else "Anonymous"
	else:
		signature.word = "Anonymous"
	
	if signature.word.length() > max_length:
		signature.word = signature.word.substr(0, max_length) + "..."

func _contains_special_characters(word: String):
	for c in word.to_lower():
		var code = c.unicode_at(0)
		if code >= 33 and code <= 126: continue
		
		return true
	
	return false
