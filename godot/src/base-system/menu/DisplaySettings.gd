class_name DisplaySettings
extends Control

signal loaded()
signal is_motion_changed()

@export var fullscreen_button: TypingButton

const SECTION = "display"
const FULLSCREEN = "fullscreen"
const IS_MOTION = "is_motion"

func load_settings(config: ConfigFile) -> void:
	var mode = config.get_value(SECTION, FULLSCREEN, -1)
	if mode != -1:
		set_fullscreen(mode == 1)
	
	GameManager.is_motion = config.get_value(SECTION, IS_MOTION, 1) == 1
	loaded.emit()

func save_settings(config: ConfigFile) -> void:
	config.set_value(SECTION, FULLSCREEN, 1 if is_fullscreen() else 0)
	config.set_value(SECTION, IS_MOTION, 1 if GameManager.is_motion else 0)

func is_fullscreen():
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func set_fullscreen(fullscreen: bool):
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED)

func set_active(v: bool):
	fullscreen_button.get_label().highlight_first = v
