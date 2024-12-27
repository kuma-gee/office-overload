extends Node2D

@export var work_label: TypingButton
@export var prepare_label: TypingButton
@export var exit_label: TypingButton
@export var files: TypedWord
@export var team: TypedWord
@export var shop_button: TypedWord

@export_category("Items")
@export var teams_node: DeskItem
@export var files_node: DeskItem

@export_category("Nodes") # onready does not work on web builds?? 
@export var settings: Settings
@export var game_modes: GameModesDialog
@export var delegator: Delegator
@export var folder: Folder
@export var teams: Folder
@export var shop: Shop

@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var stats: DocumentUI = $Stats
@onready var work_document: DocumentUI = $WorkDocument

var is_shop := false:
	set(v):
		is_shop = v
		if v:
			shop.open()
		else:
			shop.close()
var is_starting := false

func _ready() -> void:
	start()
	
	work_label.finished.connect(func():
		#var modes = GameManager.get_unlocked_modes()
		#if modes.size() == 1 or Env.is_demo():
			GameManager.start(GameManager.Mode.Work)
			work_label.reset()
		#else:
			#game_modes.grab_focus()
	)
	
	folder.closed.connect(func():
		files_node.move_in()
	)
	teams.closed.connect(func():
		teams_node.move_in()
	)

	prepare_label.finished.connect(func(): settings.grab_focus())
	
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
	if event is InputEventKey and event.keycode == KEY_TAB:
		start()
	
	if is_starting: return
	if get_viewport().gui_get_focus_owner() != null: return
	
	if is_shop:
		shop.handle_input(event)
		return
	
	delegator.handle_event(event)

	
func start():
	point_light_2d.enabled = false
	get_tree().create_timer(0.8).timeout.connect(func():
		point_light_2d.enabled = true
	)
	
	work_document.open(0.5, 10 if not GameManager.has_played else 0.0)
	files_node.move_in(0.6)
	
	if GameManager.has_current_job():
		stats.open(0.5)
	if GameManager.has_reached_junior:
		teams_node.move_in(0.7)
