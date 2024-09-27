@tool
class_name Plot2D
extends Control

var points_px := PackedVector2Array([])
var color: Color = Color.WHITE
var width: float = 1.0

var active_point_idx := -1

func _ready() -> void:
	z_index = 5

func _draw() -> void:
	if points_px.size() > 1:
		draw_polyline(points_px, color, width, false)
	
	for i in points_px.size():
		var p = points_px[i]
		var is_active = active_point_idx == i
		draw_circle(p, 2, Color.WHITE if is_active else color)
