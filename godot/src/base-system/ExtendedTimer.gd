class_name ExtendedTimer
extends Timer

signal started()
signal stopped()

var was_running = false

func _process(delta):
	if is_stopped():
		if was_running:
			stopped.emit()
		return
	elif not was_running:
		started.emit()
	
	was_running = not is_stopped()
