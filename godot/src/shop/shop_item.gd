class_name ShopItem
extends Control

signal typed()

@export var label: TypedWord
@export var price_label: Label
@export var icon: TextureRect
@export var sold_out_container: Control

var item: ShopResource

func _ready() -> void:
	if not item: return
	
	GameManager.item_purchased.connect(func(): update_stock_status())
	label.type_finish.connect(func():
		label.reset()
		typed.emit()
	)

	label.word = "%s" % tr(Shop.Items.keys()[item.type])
	price_label.text = "$%s" % item.price
	icon.texture = item.icon
	update_stock_status()
	
func update_stock_status():
	var disable = GameManager.has_item(item.type)
	#label.disabled = GameManager.has_item(item.type)
	sold_out_container.visible = disable
	label.highlight_first = not sold_out_container.visible

func get_label():
	return label
