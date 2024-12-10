class_name Shop
extends Control

enum Items {
	RUBBER_DUCK,
	PLANT,
	COFFEE,
	DO_NOT_DISTURB,
	MONEY_CAT,
	COSMETIC,
}

const ITEM_FOLDER = "res://src/shop/items/"

signal closed()

@export var container: Control
@export var item_scene: PackedScene
@export var delegator: Delegator
@export var money_container: Control
@export var details: ShopItemDetails

@onready var camera := get_viewport().get_camera_2d()

var tw: Tween

func _ready() -> void:
	#focus_mode = FOCUS_ALL
	#focus_entered.connect(_on_focus_enter)
	#focus_exited.connect(_on_focus_exit)
	
	money_container.position = Vector2.UP * 50

	for c in container.get_children():
		c.queue_free()

	# for item in DataLoader.items:
	var items = []
	for file in DirAccess.get_files_at(ITEM_FOLDER):
		var res = load(ITEM_FOLDER + file) as ShopResource
		if not res: continue
		items.append(res)

	items.sort_custom(func(a, b): return a.prices[0] < b.prices[0])
	for item in items:
		var node = item_scene.instantiate() as ShopItem
		node.item = item
		node.typed.connect(func(): details.open(item))

		container.add_child(node)
		delegator.nodes.append(node)

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		closed.emit()
	
	delegator.handle_event(event)

func open() -> void:
	tw = create_tween().set_ease(Tween.EaseType.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tw.tween_property(camera, "global_position", global_position, 0.5)
	tw.tween_property(money_container, "position", Vector2.ZERO, 0.8).set_trans(Tween.TRANS_BACK)

func close() -> void:
	tw = create_tween().set_ease(Tween.EaseType.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tw.tween_property(camera, "global_position", Vector2.ZERO, 0.5)
	tw.tween_property(money_container, "position", Vector2.UP * 50, 0.8).set_trans(Tween.TRANS_BACK)
