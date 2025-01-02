extends Sprite2D

func _ready() -> void:
	frame = GameManager.item_count(Shop.Items.PLANT) - 1
