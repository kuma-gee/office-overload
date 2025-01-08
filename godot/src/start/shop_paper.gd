class_name ShopPaper
extends DocumentUI

signal opened()
signal closed()

@export var item: ShopResource

@export var desc_label: Label
@export var price_label: Label
@export var icon_tex: TextureRect
@export var ctrl_hint: Control
@export var sold_out: Control
@export var no_money: Control

@export var buy_button: TypingButton
@export var title_button: TypingButton
@export var delegator: Delegator

@onready var orig_rot := rotation

var focus_tw: Tween

func _ready() -> void:
	title_button.finished.connect(func(): grab_focus())
	focus_entered.connect(func():
		if focus_tw and focus_tw.is_running(): return
		focus_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
		focus_tw.tween_property(self, "position", Vector2(-size.x / 2, -size.y), 0.5)
		focus_tw.tween_property(self, "rotation", 0, 0.5)
		focus_tw.tween_callback(func(): z_index = 10)
		title_button.get_label().fill_all = true
		opened.emit()
	)
	focus_exited.connect(func():
		if focus_tw and focus_tw.is_running(): return
		focus_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
		focus_tw.tween_property(self, "global_position", orig_pos, 0.5)
		focus_tw.tween_property(self, "rotation", orig_rot, 0.5)
		focus_tw.tween_callback(func(): z_index = 0)
		title_button.get_label().fill_all = false
		closed.emit()
	)
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

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)

func get_label():
	return title_button.get_label()
