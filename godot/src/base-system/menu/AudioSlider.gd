class_name AudioSlider
extends HSlider

@export var bus_name := "Master"
@export var vol_range = 60
@export var vol_offset = 30

var master_id

func _ready():
	master_id = AudioServer.get_bus_index(bus_name)
	connect("value_changed", self._volume_changed)
	value = get_volume_percentage()

func _volume_changed(v: float):
	if v == 0:
		AudioServer.set_bus_mute(master_id, true)
	else:
		AudioServer.set_bus_mute(master_id, false)
		AudioServer.set_bus_volume_db(master_id, get_volume(v))

func get_volume(percentage: float) -> float:
	var vol_value = -vol_range + (vol_range * percentage / 100) # Volume from -vol_range to 0
	vol_value += vol_offset
	return vol_value

func get_volume_percentage():
	var volume = AudioServer.get_bus_volume_db(master_id)
	return (volume - vol_offset + vol_range) * 100 / vol_range # Just reversed the equation of #get_volume

func highlight(v: bool):
	if not v:
		remove_theme_stylebox_override("slider")
		remove_theme_stylebox_override("grabber_area")
		remove_theme_stylebox_override("grabber_area_highlight")
		return
	
	var slider = get_theme_stylebox("slider").duplicate() as StyleBoxFlat
	slider.border_color = Color.WHITE
	add_theme_stylebox_override("slider", slider)
	
	var grabber = get_theme_stylebox("grabber_area").duplicate() as StyleBoxFlat
	grabber.border_color = Color.WHITE
	add_theme_stylebox_override("grabber_area", grabber)
	add_theme_stylebox_override("grabber_area_highlight", grabber)
