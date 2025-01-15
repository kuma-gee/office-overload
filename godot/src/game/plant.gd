extends GameDeskItem

func _ready() -> void:
	super._ready()
	
	var count = GameManager.item_count(Shop.Items.PLANT)
	if count > 0:
		frame = count - 1
