extends Label

@export var prefix := ""

func _ready() -> void:
	update()
	GameManager.item_purchased.connect(func(): update())

func update():
	text = "%s$%s" % [prefix, GameManager.money]
