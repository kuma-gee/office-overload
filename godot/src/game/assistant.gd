extends GameDeskItem

@onready var second_assistant: GameDeskItem = $SecondAssistant

func _ready() -> void:
	super._ready()
	second_assistant.visible = GameManager.item_count(Shop.Items.ASSISTANT) >= 2
