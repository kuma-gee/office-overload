class_name Shop
extends StartView

enum Items {
	RUBBER_DUCK,
	PLANT,
	COFFEE,
	ASSISTANT,
	MONEY_CAT,
}

const ITEM_FOLDER = "res://src/shop/items/"

@export var paper_container: Control
@export var money_container: Control

func _ready() -> void:
	for c in paper_container.get_children():
		delegator.nodes.append(c)

func setup_papers():
	var delays = [0.5, 0.7, 0.7, 1.0, 0.9]
	for c in paper_container.get_children():
		if c is ShopPaper:
			if not GameManager.is_item_available(c.item.type): continue
			
			var i = 0 #randi_range(0, delays.size() - 1)
			if delays.is_empty():
				c.open(1.0)
			else:
				c.open(delays[i])
				delays.remove_at(i)
				
			c.opened.connect(func(): delegator.unfocus())
			c.closed.connect(func(): delegator.focus())
