class_name CheckboxTexture
extends Control

@export var unchecked: Texture2D
@export var checked: Texture2D
@export var tex: TextureRect

var is_checked := false:
	set(v):
		is_checked = v
		tex.texture = checked if is_checked else unchecked
	
func _ready() -> void:
	is_checked = false
