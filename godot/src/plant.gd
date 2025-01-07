extends GameDeskItem

func _ready() -> void:
	super._ready()
	frame = GameManager.item_count(Shop.Items.PLANT) - 1
