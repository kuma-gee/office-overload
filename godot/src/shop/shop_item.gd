class_name ShopItem
extends Control

signal typed()

@export var label: TypedWord
@export var price_label: Label
@export var icon: TextureRect
@export var sold_out_container: Control
@export var light: Light2D

var item: ShopResource

func _ready() -> void:
	if not item: return
	
	GameManager.item_purchased.connect(func(): update_stock_status())
	label.type_finish.connect(func():
		label.reset()
		typed.emit()
	)

	label.word = "%s" % tr(Shop.Items.keys()[item.type])
	price_label.text = "$%s" % GameManager.item_price(item)
	icon.texture = item.icon
	update_stock_status()
	
func update_stock_status():
	var disable = GameManager.is_item_max(item)
	#label.disabled = GameManager.has_item(item.type)
	sold_out_container.visible = disable
	#label.highlight_first = not disable
	light.enabled = not disable

func get_label():
	return label
