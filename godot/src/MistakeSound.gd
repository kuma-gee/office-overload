extends DebounceAudio

@export var delta := 0.1
@onready var original_pitch := pitch_scale

func play_debounce(t := 0.1):
	pitch_scale = [original_pitch - delta, original_pitch, original_pitch + delta].pick_random()
	super.play_debounce(t)
