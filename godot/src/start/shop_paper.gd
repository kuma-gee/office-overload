class_name ShopPaper
extends FocusedDocument

@export var item: ShopResource

@export var desc_label: Label
@export var price_label: Label
@export var value_label: Label
@export var icon_tex: TextureRect
@export var ctrl_hint: Control
@export var sold_out: Control
@export var no_money: Control
@export var esc_tex: Control

@export var buy_button: TypingButton

func _ready() -> void:
	if Env.is_demo():
		original_pos_offset_y = -30
	
	super._ready()
	buy_button.finished.connect(func():
		GameManager.buy_item(item)
		await send()
		_update()
		open(0.2)
	)
	
	icon_tex.texture = item.icon
	var type_str = Shop.Items.keys()[item.type]
	title_button.update(tr(type_str))
	desc_label.text = tr("%s_DESC" % type_str)
	ctrl_hint.visible = item.type == Shop.Items.COFFEE
	
	focus_entered.connect(func(): esc_tex.show())
	focus_exited.connect(func(): esc_tex.hide())

	_update()
	esc_tex.hide()

func _update():
	var count = GameManager.item_count(item.type)
	var value = GameManager.get_item_value(item.type, count + 1)
	value_label.visible = value > 0
	if value > 0:
		var sign = "+" if item.type in [Shop.Items.MONEY_CAT] else "-"
		value_label.text = "%s%.0f%%" % [sign, value * 100]

	var price = GameManager.item_price(item)
	price_label.text = "$%s" % price
	
	var is_max = GameManager.is_item_max(item)
	var disabled = GameManager.money < price
	no_money.visible = not is_max and disabled 
	buy_button.visible = not is_max and not disabled
	buy_button.get_label().word = tr("PURCHASE") if count <= 0 else tr("UPGRADE")
	
	var is_coffee = item.type == Shop.Items.COFFEE
	sold_out.visible = is_max #and not is_coffee
	#ctrl_hint.visible = is_max and is_coffee
