class_name Folder
extends Control

@export var papers: Papers

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
	for c in papers.get_children():
		c.get_label().highlight_first = focus

func open():
	animation_player.play("open_folder")
	grab_focus()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		get_viewport().gui_release_focus()
		animation_player.play("close_folder")
	
	delegator.handle_event(event)
	get_viewport().set_input_as_handled()
