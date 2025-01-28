class_name Folder
extends Control

signal closed()

@export var papers: Papers
@export var overlay: Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var delegator: Delegator = $Delegator
@onready var panel_container: PanelContainer = $TextureRect/PanelContainer

func _ready() -> void:
	panel_container.show()
	animation_player.play("RESET")
	
	for c in papers.get_children():
		delegator.nodes.append(c)
	
	focus_entered.connect(func(): set_focused(true))
	focus_exited.connect(func(): set_focused(false))

func set_focused(focus = false):
	if not animation_player.is_playing():
		if not focus:
			animation_player.speed_scale = 1.0 if GameManager.is_motion else 1000.
			animation_player.play("show_overlay")
		else:
			animation_player.speed_scale = 1.0 if GameManager.is_motion else 1000.
			animation_player.play_backwards("show_overlay")
	
	for c in papers.get_children():
		c.get_label().highlight_first = focus

func open():
	animation_player.speed_scale = 1.0 if GameManager.is_motion else 1000.
	animation_player.play("open_folder")
	grab_focus()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused() and not animation_player.is_playing():
		get_viewport().gui_release_focus()
		animation_player.speed_scale = 1.0 if GameManager.is_motion else 1000.
		animation_player.play("close_folder")
	
	delegator.handle_event(event)
	get_viewport().set_input_as_handled()

func close_finished():
	closed.emit()
