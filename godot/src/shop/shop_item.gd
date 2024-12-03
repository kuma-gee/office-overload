class_name ShopItem
extends Control

@export var label: TypedWord
@export var price_label: Label
@export var icon: TextureRect
@export var sold_out_container: Control

var item: ShopResource

func _ready() -> void:
	if not item: return
	
	label.type_finish.connect(func():
		if GameManager.buy_item(item.type, item.price) and not label.disabled:
			update_stock_status()
	)

	label.word = "%s" % tr(Shop.Items.keys()[item.type])
	price_label.text = "$%s" % item.price
	icon.texture = item.icon
	update_stock_status()
	
func update_stock_status():
	label.disabled = GameManager.has_item(item.type)
	sold_out_container.visible = label.disabled
	label.highlight_first = not sold_out_container.visible

func get_label():
	return label
