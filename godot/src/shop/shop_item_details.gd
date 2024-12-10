class_name ShopItemDetails
extends Control

@export var icon: TextureRect
@export var name_label: Label
@export var price_label: Label
@export var desc_label: Label
@export var purchase_word: TypedWord
@export var sold_out_label: RichTextLabel

@onready var delegator: Delegator = $Delegator
@onready var original_pos := global_position

var current_item: ShopResource:
	set(v):
		current_item = v
		
		if current_item:
			icon.texture = current_item.icon
			var type_str = Shop.Items.keys()[current_item.type]
			name_label.text = tr(type_str)

			var price = GameManager.item_price(current_item)
			price_label.text = "$%s" % price
			desc_label.text = tr("%s_DESC" % type_str)
			purchase_word.visible = not GameManager.is_item_max(current_item)
			purchase_word.word = tr("PURCHASE") if GameManager.item_count(current_item.type) <= 0 else tr("UPGRADE")
			sold_out_label.visible = not purchase_word.visible

var tw: Tween

func _ready() -> void:
	focus_mode = FOCUS_ALL
	focus_exited.connect(func(): close())
	
	purchase_word.type_finish.connect(func():
		purchase_word.reset()
		
		if not current_item: return
		if GameManager.is_item_max(current_item): return
		
		GameManager.buy_item(current_item)
	)
	sold_out_label.text = "[center]%s[/center]" % tr("SOLD_OUT")
	
	_hide_animation()

func _open_animation():
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position", original_pos, 0.5)

func _hide_animation():
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position", original_pos + Vector2.RIGHT * size.x, 0.5)

func open(item: ShopResource):
	current_item = item
	_open_animation()
	grab_focus()

func close():
	current_item = null
	_hide_animation()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
	
	delegator.handle_event(event)
