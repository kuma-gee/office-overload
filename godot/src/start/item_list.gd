extends Control

@export var item: ShopResource
@export var label: TypedWord
@export var checkbox: CheckBox
@export var texture: TextureRect
@export var count: Label
@export var value_label: Label

func _ready() -> void:
	label.type_finish.connect(func(): GameManager.toggle_item_used(item.type))
	value_label.hide() 

	var type_str = Shop.Items.keys()[item.type]
	label.word = tr(type_str)
	texture.texture = item.icon

	GameManager.item_used_toggled.connect(func(type):
		if type == item.type:
			_update_checkbox()
	)
	_update_checkbox()
	
	GameManager.item_purchased.connect(func(): _update_status())
	_update_status()

func _update_checkbox():
	checkbox.button_pressed = GameManager.is_item_used(item.type) and _can_enable()

func _update_status():
	visible = GameManager.item_count(item.type) > 0
	count.text = "%s/%s" % [GameManager.item_count(item.type), item.prices.size()]
	
	if _is_assistant():
		value_label.text = "-$%s" % [GameManager.get_assistant_cost()]
		value_label.show()
	
	var lbl = get_label()
	lbl.disabled = not _can_enable()
	_update_checkbox()

func _is_assistant():
	return item.type == Shop.Items.ASSISTANT

func _can_enable():
	return not _is_assistant() or GameManager.money >= GameManager.get_assistant_cost()

func get_label():
	return label.get_label()
