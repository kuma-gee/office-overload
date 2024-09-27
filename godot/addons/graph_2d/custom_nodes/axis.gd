@tool
extends Control

var default_color := Color.WHITE
var default_font: Font
var default_font_size: int

enum {
	POINT = 0,
	LABEL,
}

var vert_grad: Array # [Vector2, String]
var hor_grad: Array
var x_label: String
var y_label: String
var show_x_ticks: bool
var show_y_ticks: bool
var show_x_numbers: bool
var show_y_numbers: bool
var show_vertical_line: bool
var show_horizontal_line: bool


func _ready():
	name = "Axis"
	default_font = get_theme_default_font()
	default_font_size = get_theme_default_font_size()
	if not default_font_size:
		default_font_size = 10
	
	var x_label_node = Label.new()
	x_label_node.name = "XLabel"
	add_child(x_label_node)
	var y_label_node = Label.new()
	y_label_node.name = "YLabel"
	y_label_node.rotation = -PI/2
	add_child(y_label_node)
	

func _draw() -> void:
	if vert_grad.is_empty() or hor_grad.is_empty(): return
	
	var topleft: Vector2 = vert_grad.front()[POINT]
	var topright: Vector2 = Vector2(hor_grad.back()[POINT].x, vert_grad.front()[POINT].y)
	var bottomright: Vector2 = hor_grad.back()[POINT]
	
	if show_x_ticks:
		for grad in hor_grad: 
			draw_line(grad[POINT], grad[POINT] + Vector2(0, 5), default_color, 1)
	
	if show_x_numbers:
		for grad in hor_grad:
			draw_string(default_font, grad[POINT] + Vector2(0, 20), grad[LABEL], HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size, default_color)
	
	if show_horizontal_line:
		draw_line(hor_grad.front()[POINT], hor_grad.back()[POINT], default_color, 1)

	if show_y_ticks:
		for grad in vert_grad:
			draw_line(grad[POINT], grad[POINT] - Vector2(5, 0), default_color, 1)
	
	if show_y_numbers:
		for grad in vert_grad:
			draw_string(default_font, grad[0] + Vector2(-30, 2.5), grad[1], HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size, default_color)
		
	if show_vertical_line:
		draw_line(topleft, vert_grad.back()[POINT], default_color, 1)

	get_node("XLabel").text = x_label
	get_node("YLabel").text = y_label
	get_node("XLabel").position = Vector2((bottomright.x + topleft.x)/2, bottomright.y + 12)
	get_node("YLabel").position = Vector2(5, (bottomright.y + topleft.y)/2)
