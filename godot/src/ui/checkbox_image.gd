class_name CheckboxImage
extends TextureRect

@onready var color_rect: ColorRect = $ColorRect

var value:
	set(v):
		value = v
		color_rect.visible = v
