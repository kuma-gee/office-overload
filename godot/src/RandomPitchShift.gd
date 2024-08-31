class_name RandomPitchShift
extends AudioStreamPlayer

@export var delta := 0.1
@onready var original_pitch := pitch_scale

func play_random_pitched():
	pitch_scale = [original_pitch - delta, original_pitch, original_pitch + delta].pick_random()
	play()
