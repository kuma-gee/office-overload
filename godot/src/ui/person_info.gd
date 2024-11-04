class_name PersonInfo
extends Control

signal selected()
signal overloaded()

@export var label: TypedWord
@export var progress_bar: TextureProgressBar
@export var overload_timer: Timer
@export var selected_sign: Control
@export var document_process_speed := 0.1
@export var stress_decrease := 20.0
@export var stress_increase := 80.0

@export var sprite: Sprite2D

@export_category("Label Slide")
@export var label_container: Control
@export var slide_dir := Vector2.ZERO
@onready var start_pos := label_container.position

const NORMAL_SPRITE = 0
const STRESSED_SPRITE = 1

var haika: Haika
var tw: Tween

var stress_level = Haika.StressLevel.LOW
var is_selected := false:
	set(v):
		is_selected = v
		selected_sign.visible = v
		label.active = v

var current_stress := 0.0:
	set(v):
		current_stress = max(v, 0) #clamp(v, 0, 100)
		progress_bar.value = current_stress
		sprite.frame = NORMAL_SPRITE if current_stress <= 90 else STRESSED_SPRITE
		
		if current_stress >= 1:
			if overload_timer.is_stopped():
				overload_timer.start()
		else:
			overload_timer.stop()

var current_documents := 0
var document_process := 0.0:
	set(v):
		document_process = clamp(v, 0, 1)
		if document_process >= 1:
			current_documents -= 1
			current_stress -= stress_decrease
			document_process = 0

var person = "":
	set(v):
		person = v
		stress_level = GameManager.subordinates[v]
		set_word(v)

func _ready() -> void:
	current_stress = 0
	is_selected = false
	label_container.position = get_hide_position()
	label.type_finish.connect(func():
		label.reset()
		selected.emit()
	)

	overload_timer.timeout.connect(func(): overloaded.emit())

func _process(delta: float) -> void:
	if haika.is_gameover: return
	
	if current_documents > 0:
		document_process += document_process_speed * delta
		current_stress += (stress_increase / max(current_stress, 1.0)) * current_documents * delta / stress_level
		
	#current_stress -= delta * stress_decrease

func set_word(w: String):
	label.word = w

func get_word():
	return label.word

func get_label():
	return label

func get_hide_position():
	return start_pos - slide_dir

func slide_in():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(label_container, "position", start_pos, 0.5)

func slide_out():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(label_container, "position", get_hide_position(), 0.5)
