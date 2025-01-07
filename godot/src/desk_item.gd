class_name GameDeskItem
extends Sprite2D

const GROUP = "GameDeskItem"
const ITEM_SHADOW = preload("res://src/item_shadow.tres")

@export var weight := 1.0
@onready var orig_pos = position

var tw: Tween

func _ready() -> void:
	add_to_group(GROUP)
	
	#var shadow = Sprite2D.new()
	#shadow.texture = texture
	#shadow.material = ITEM_SHADOW
	#add_child(shadow)
	#shadow.top_level = true
	#shadow.z_index = -1

func slammed():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position", orig_pos + Vector2.UP * 3 / weight, 0.15)
	tw.tween_property(self, "position", orig_pos + Vector2.ZERO, 0.15)
