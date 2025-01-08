class_name Settings
extends FocusedDialog

const CONFIG_FILE = "user://settings.cfg"

@export var overlay: ColorRect
@export var sliders: Array[TypingSlider] = []

@export var display_settings: DisplaySettings
@export var _audio: AudioSettings

@onready var settings := [_audio, display_settings]

var _logger = Logger.new("Settings")
var _config = ConfigFile.new()

var active_slider: TypingSlider:
	set(v):
		if active_slider:
			active_slider.z_index = 0
		
		active_slider = v
		overlay.visible = v != null
		
		if active_slider:
			active_slider.z_index = 20


func _ready():
	super._ready()
	overlay.hide()
	_load_settings()

	visibility_changed.connect(func(): if not visible: _save_config())
	for s in sliders:
		s.opened.connect(func(open): active_slider = s if open else null)
		s.activated.connect(func(active):
			for other_s in sliders:
				other_s.set_active(not active)
			display_settings.set_active(not active)
		)
	
	focus_exited.connect(func():
		for slider in sliders:
			slider.set_control_visible(false)
	)


func _load_settings():
	var error = _config.load(CONFIG_FILE)
	if error != OK:
		_logger.error("Failed to load settings: %s" % error)
	
	_logger.debug("Loading settings")
	for setting in settings:
		if setting:
			setting.load_settings(_config)

func _exit_tree():
	_save_config()

func _save_config():
	if Env.is_web(): return
	
	_logger.debug("Saving settings")
	for setting in settings:
		if setting:
			setting.save_settings(_config)
	_config.save(CONFIG_FILE)

func _gui_input(event):
	if active_slider:
		active_slider.handle_event(event)
	else:
		if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
			get_viewport().gui_release_focus()
		
		delegator.handle_event(event)

	get_viewport().set_input_as_handled()
