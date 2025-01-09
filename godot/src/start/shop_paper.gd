class_name ShopPaper
extends FocusedDocument

@export var item: ShopResource

@export var desc_label: Label
@export var price_label: Label
@export var icon_tex: TextureRect
@export var ctrl_hint: Control
@export var sold_out: Control
@export var no_money: Control

@export var buy_button: TypingButton

func _ready() -> void:
	super._ready()
	buy_button.finished.connect(func(): GameManager.buy_item(item))
	
	icon_tex.texture = item.icon
	var type_str = Shop.Items.keys()[item.type]
	title_button.update(tr(type_str))

	var price = GameManager.item_price(item)
	price_label.text = "$%s" % price
	desc_label.text = tr("%s_DESC" % type_str)
	no_money.visible = GameManager.money < price
	
	buy_button.visible = not GameManager.is_item_max(item) and not no_money.visible
	buy_button.get_label().word = tr("PURCHASE") if GameManager.item_count(item.type) <= 0 else tr("UPGRADE")
	var disabled = GameManager.money < GameManager.item_price(item)
	
	var is_coffee = item.type == Shop.Items.COFFEE
	sold_out.visible = not buy_button.visible
	ctrl_hint.visible = not buy_button.visible and is_coffee
	
	buy_button.get_label().disabled = disabled
	buy_button.get_label().highlight_first = not disabled
