extends Node

#@export var sfx_player_pool: Node
#@export var paper_move_in_sfx: AudioStream
#@export var paper_move_in_volume := .0

@onready var button_sound = $ButtonSound
@onready var press_sound = $PressSound
@onready var type_sound = $TypeSound
@onready var type_mistake_sound: DebounceAudio = $TypeMistakeSound
@onready var paper_move_in: RandomPitchShift = $PaperMoveIn
@onready var paper_open: RandomPitchShift = $PaperOpen
@onready var paper_close: RandomPitchShift = $PaperClose
@onready var folder_slide: RandomPitchShift = $FolderSlide
@onready var folder_open: RandomPitchShift = $FolderOpen


func play_button_sound():
	button_sound.play()
	
func play_press_sound():
	press_sound.play()

func play_type_sound():
	type_sound.play_random_pitched()

func play_type_mistake():
	type_mistake_sound.play_debounce()

func play_paper_move():
	var node = paper_move_in.duplicate() as AudioStreamPlayer
	add_child(node)
	node.finished.connect(func(): node.queue_free())
	node.play_random_pitched()

func play_paper_open():
	paper_open.play_random_pitched()
	
func play_paper_close():
	paper_close.play_random_pitched()

func play_folder_slide():
	folder_slide.play()

func play_folder_open():
	folder_open.play_random_pitched()
