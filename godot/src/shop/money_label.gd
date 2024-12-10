extends Label

func _ready() -> void:
	update()
	GameManager.item_purchased.connect(func(): update())

func update():
	text = "$%s" % GameManager.money
