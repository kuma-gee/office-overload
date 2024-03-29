extends Node

@export var input: PlayerInput

var logger = Logger.new("DeviceSwitcher")

func _unhandled_input(event: InputEvent):
	if input == null or event.device != input.device_id or input.is_player_event(event):
		return

	var joypad = event is InputEventJoypadButton
	if input.joypad != joypad:
		logger.info(
			"Changing device %s to %s" % [input.device_id, "controller" if joypad else "keyboard"]
		)
		input.joypad = joypad
