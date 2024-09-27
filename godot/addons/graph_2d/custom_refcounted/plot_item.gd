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

var coordinate

func _init(obj, l, c, w):
	_curve = _LineCurve.new()
	_graph = obj
	label = l
	_curve.name = l if l else "RandomName%s" % randi_range(1, 100)
	_curve.color = c
	color = c
	_curve.width = w
	_graph.get_node("PlotArea").add_child(_curve)

func set_active_point(pt: Vector2):
	_curve.active_point_idx = _points.find(pt)
	_curve.queue_redraw()
	coordinate.text = "%.0f WPM" % [pt.y]

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


## Delete instance
func delete():
	_graph.get_node("PlotArea").remove_child(_curve)
	_curve.queue_free()
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
