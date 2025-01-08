extends Node2D

@export var work_label: TypingButton
@export var settings_label: TypingButton
@export var exit_label: TypingButton
@export var crunch_mode: TypingButton
@export var multiplayer_mode: TypingButton

@export var files: TypedWord
@export var team: TypedWord
@export var shop_button: TypedWord

@export_category("Items")
@export var teams_node: DeskItem
@export var files_node: DeskItem

@export_category("Nodes") # onready does not work on web builds?? 
@export var settings: Settings
@export var folder: Folder
@export var teams: Folder
@export var shop: Shop
@export var game_modes_key: Control
@export var crunch_mode_container: Control
@export var multiplayer_mode_container: Control
@export var ceo_level_select: Control

@export_category("Delegators")
@export var delegator: Delegator
@export var shift_delegator: Delegator

@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var stats: DocumentUI = $Stats
@onready var work_document: DocumentUI = $WorkDocument
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum DelegateMode {
	Default,
	Shift,
}

@onready var delegator_map = {
	DelegateMode.Default: delegator,
	DelegateMode.Shift: shift_delegator,
}

var mode := DelegateMode.Default:
	set(v):
		mode = v
		
		for m in delegator_map.keys():
			if m == mode:
				delegator_map[m].focus()
			else:
				delegator_map[m].unfocus()

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
		if GameManager.finished_game:
			ceo_level_select.grab_focus()
		else:
			GameManager.start(GameManager.Mode.Work)
	)
	
	crunch_mode.finished.connect(func(): GameManager.start(GameManager.Mode.Crunch))
	exit_label.finished.connect(func(): GameManager.quit_game())
	
	settings_label.finished.connect(func(): settings.grab_focus())
	folder.closed.connect(func(): files_node.move_in())
	teams.closed.connect(func(): teams_node.move_in())
	
	files.type_finish.connect(func():
		await files_node.move_open()
		folder.open()
	)
	team.type_finish.connect(func():
		await teams_node.move_open()
		teams.open()
	)
	shop_button.type_finish.connect(func(): is_shop = true)
	shop.closed.connect(func(): is_shop = false)
	
	game_modes_key.visible = GameManager.unlocked_modes.size() > 1
	crunch_mode_container.visible = GameManager.is_mode_unlocked(GameManager.Mode.Crunch)
	multiplayer_mode_container.visible = GameManager.is_mode_unlocked(GameManager.Mode.Multiplayer)
	
func _unhandled_input(event: InputEvent) -> void:
	if is_starting: return
	if get_viewport().gui_get_focus_owner() != null: return
	
	if is_shop:
		shop.handle_input(event)
		return
	
	if game_modes_key.visible:
		if event.is_action_pressed("special_mode") and mode != DelegateMode.Shift:
			animation_player.play("alt_page")
			mode = DelegateMode.Shift
		elif event.is_action_released("special_mode") and mode == DelegateMode.Shift:
			animation_player.play_backwards("alt_page")
			mode = DelegateMode.Default
	
	var deleg = delegator_map[mode]
	deleg.handle_event(event)
	
func start():
	point_light_2d.enabled = false
	get_tree().create_timer(0.8).timeout.connect(func():
		point_light_2d.enabled = true
	)
	
	work_document.open(0.5, 10 if not GameManager.has_played else 0.0)
	files_node.move_in(0.6)
	
	if GameManager.has_current_job():
		stats.open(0.5)
	if GameManager.shown_stress_tutorial:
		teams_node.move_in(0.7)
