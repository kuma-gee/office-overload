extends GameDeskItem

func _ready() -> void:
	super._ready()
	visible = GameManager.item_count(Shop.Items.COFFEE) > 0
	
	frame = 0
	GameManager.coffee_used.connect(func(): frame = 1)
