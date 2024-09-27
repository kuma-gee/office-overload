@tool
extends Label

func _ready():
	name = "Coordinate"
	anchor_right = 1
	anchor_left = 1
	offset_right = 0
	offset_top = -20
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	
	text = ""
	add_theme_color_override("font_color", Color.WHITE)
