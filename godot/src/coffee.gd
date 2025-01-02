extends Sprite2D

func _ready() -> void:
	visible = GameManager.item_count(Shop.Items.COFFEE) > 0
	
	frame = 0
	GameManager.coffee_used.connect(func(): frame = 1)
