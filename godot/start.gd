extends Node

@export var work_label: TypedWord
@export var prepare_label: TypedWord
@export var files: TypedWord
@export var team: TypedWord
@export var shop_button: TypedWord

@export_category("Items")
@export var prepare_node: DeskItem
@export var teams_node: DeskItem
@export var files_node: DeskItem

@export_category("Nodes") # onready does not work on web builds?? 
@export var settings: Settings
@export var game_modes: GameModesDialog
@export var delegator: Delegator
@export var folder: Folder
@export var teams: Folder
@export var shop: Shop

var is_shop := false:
	set(v):
		is_shop = v
		if v:
			shop.open()
		else:
			shop.close()
var is_starting := false
var quit_warning_open := false

func _ready():
	get_tree().paused = false
	GameManager.game_started.connect(func(): is_starting = true)
	
	prepare_node.move_in(0.5)
	if GameManager.has_played:
		files_node.move_in(0.6)
	if GameManager.has_reached_junior:
		teams_node.move_in(0.7)
	
	work_label.type_finish.connect(func():
		#var modes = GameManager.get_unlocked_modes()
		#if modes.size() == 1 or Env.is_demo():
			GameManager.start(GameManager.Mode.Work)
			work_label.reset()
		#else:
			#game_modes.grab_focus()
	)
	
	settings.focus_exited.connect(func(): prepare_node.move_in())
	folder.closed.connect(func(): files_node.move_in())
	teams.closed.connect(func(): teams_node.move_in())

	prepare_label.type_finish.connect(func():
		await prepare_node.move_open()
		settings.grab_focus()
		prepare_label.reset()
	)
	files.type_finish.connect(func():
		await files_node.move_open()
		folder.open()
		files.reset()
	)
	team.type_finish.connect(func():
		await teams_node.move_open()
		teams.open()
		team.reset()
	)
	shop_button.type_finish.connect(func():
		is_shop = true
		shop_button.reset()
	)
	shop.closed.connect(func(): is_shop = false)

func _unhandled_input(event: InputEvent) -> void:
	if is_starting: return
	if get_viewport().gui_get_focus_owner() != null: return
	
	if is_shop:
		shop.handle_input(event)
		return
	
	delegator.handle_event(event)
