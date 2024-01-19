class_name ManualLoopAudio
extends AudioStreamPlayer

var next_pitch = -1
var next_stream: AudioStream

func _ready():
	finished.connect(func(): do_play())

func do_play():
	if next_pitch > 0:
		pitch_scale = next_pitch
		next_pitch = -1
		
	if next_stream and next_stream != stream:
		stream = next_stream

	play()
