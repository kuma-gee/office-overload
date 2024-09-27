class_name UnlockedMode
extends Control

@export var particles: Array[GPUParticles2D] = []
@export var effect: EffectRoot
@export var label: Label

func _ready() -> void:
	hide()
	
	focus_exited.connect(func():
		effect.reverse_effect()
		show()
	)

func unlocked_mode(mode: GameManager.Mode):
	grab_focus()

	effect.do_effect()
	label.text = "%s" % GameManager.Mode.keys()[mode]
	
	for p in particles:
		p.emitting = true

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().gui_release_focus()
	get_viewport().set_input_as_handled()
