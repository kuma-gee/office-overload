class_name ManualLoopAudio
extends AudioStreamPlayer

var next_pitch = -1

func _ready():
	finished.connect(func(): do_play())

func do_play():
	if next_pitch > 0:
		pitch_scale = next_pitch
		next_pitch = -1
	play()
