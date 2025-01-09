extends Control

@export var item: ShopResource
@export var label: TypedWord
@export var checkbox: CheckBox
@export var texture: TextureRect

func _ready() -> void:
	label.type_finish.connect(func(): GameManager.toggle_item_used(item.type))

	var type_str = Shop.Items.keys()[item.type]
	label.word = tr(type_str)
	texture.texture = item.icon

	GameManager.item_used_toggled.connect(func(type):
		if type == item.type:
			_update_checkbox()
	)
	_update_checkbox()
	
	GameManager.item_purchased.connect(func(): _update_visible())
	_update_visible()

func _update_checkbox():
	checkbox.button_pressed = GameManager.is_item_used(item.type)

func _update_visible():
	visible = GameManager.item_count(item.type) > 0

func get_label():
	return label.get_label()
