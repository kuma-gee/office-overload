class_name PlotItem
extends RefCounted

## PlotItem offers properties and some methods on the plot.
##
## You do not directly create a [b]PlotItem[/b] type variable. This is created with the method [method Graph2D.add_plot_item].

## Plot label
var label: String:
	set(value):
		label = value
		if not label.is_empty():
			_curve.name = label
	get:
		return label

## Line color
var color: Color = Color.WHITE:
	set(value):
		color = value
		_curve.color = color

## Line thickness
var thickness: float = 1.0:
	set(value):
		if value > 0.0:
			thickness = value
			_curve.width = thickness
		
var _curve: Plot2D
var _LineCurve = preload("res://addons/graph_2d/custom_nodes/plot_2d.gd")
var _points: PackedVector2Array
var _graph
var show_points = true:
	set(v):
		show_points = v
		_curve.show_points = v

var coordinate: Label
var legend: Label

func _init(obj, l, c, w):
	_curve = _LineCurve.new()
	_graph = obj
	label = l
	_curve.name = l if l else "RandomName%s" % randi_range(1, 100)
	_curve.color = c
	color = c
	_curve.width = w
	_graph.get_node("PlotArea").add_child(_curve)
	
	legend = Label.new()
	legend.text = l
	legend.add_theme_font_size_override("font_size", 6)
	legend.add_theme_color_override("font_color", c)
	_graph.add_child(legend)

func set_active_point(pt: Vector2):
	if coordinate:
		var pt_id = _points.find(pt)
		_curve.active_point_idx = pt_id
		_curve.queue_redraw()
		
		await coordinate.get_tree().create_timer(0.1).timeout
		coordinate.text = "%.0f %s" % [pt.y, label]
		coordinate.global_position = _curve.global_position + _curve.points_px[pt_id] + Vector2(2, 2)
		coordinate.show()

func get_point_from_active(delta: int):
	var idx = _curve.active_point_idx + delta
	if idx >= 0 and idx < _points.size():
		return _points[idx]
	return null

func find_point(pt: Vector2, dist: float):
	for p in _points:
		var delta = abs(pt.x - p.x)
		if delta <= dist:
			return p
			
	return null

## Add point to plot
func add_point(pt: Vector2):
	_points.append(pt)
	var point = pt.clamp(Vector2(_graph.x_min, _graph.y_min), Vector2(_graph.x_max, _graph.y_max))
	var pt_px: Vector2
	pt_px.x = remap(point.x, _graph.x_min, _graph.x_max, 0, _graph.get_node("PlotArea").size.x)
	pt_px.y = remap(point.y, _graph.y_min, _graph.y_max, _graph.get_node("PlotArea").size.y, 0)
	_curve.points_px.append(pt_px)
	_curve.queue_redraw()
	
	if _curve.active_point_idx < 0:
		set_active_point(pt)

func update_legend():
	var pt = _curve.points_px[_curve.points_px.size() - 1]
	legend.global_position = _curve.global_position + pt + Vector2(2, -legend.size.y / 2)

## Remove point from plot
func remove_point(pt: Vector2):
	if _points.find(pt) == -1:
		printerr("No point found with the coordinates of %s" % str(pt))
	_points.remove_at(_points.find(pt))
	var point = pt.clamp(Vector2(_graph.x_min, _graph.y_min), Vector2(_graph.x_max, _graph.y_max))
	var pt_px: Vector2
	pt_px.x = remap(point.x, _graph.x_min, _graph.x_max, 0, _graph.get_node("PlotArea").size.x)
	pt_px.y = remap(point.y, _graph.y_min, _graph.y_max, _graph.get_node("PlotArea").size.y, 0)
	_curve.points_px.remove_at(_curve.points_px.find(pt_px))
	_curve.queue_redraw()


## Remove all points from plot
func remove_all():
	_points.clear()
	_curve.points_px.clear()
	_curve.queue_redraw()
	if coordinate:
		coordinate.hide()


## Delete instance
func delete():
	_graph.get_node("PlotArea").remove_child(_curve)
	_curve.queue_free()
	legend.queue_free()
	if coordinate:
		coordinate.hide()
	call_deferred("unreference")


func _redraw():
	_curve.points_px.clear()
	for pt in _points:
		if pt.x >= _graph.x_min and pt.x <= _graph.x_max:
			var point = pt.clamp(Vector2(_graph.x_min, _graph.y_min), Vector2(_graph.x_max, _graph.y_max))
			var pt_px: Vector2
			pt_px.x = remap(point.x, _graph.x_min, _graph.x_max, 0, _graph.get_node("PlotArea").size.x)
			pt_px.y = remap(point.y, _graph.y_min, _graph.y_max, _graph.get_node("PlotArea").size.y, 0)
			_curve.points_px.append(pt_px)
	_curve.queue_redraw()
