class_name LobbyOffice
extends DocumentUI

@export var row_scene: PackedScene
@export var player_container: Control
@export var lobby_container: Control

@export var title_label: Label
@export var closed_label: Label
@export var failed_label: Label

@export var start_btn: TypingButton
@export var loading: RichTextLabel
@export var delegator: Delegator

var is_closed := false:
	set(v):
		is_closed = v
		closed_label.visible = v
		lobby_container.visible = not v

var is_owner := false
var logger := Logger.new("LobbyOffice")

func _ready() -> void:
	super()
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_IGNORE
	
	failed_label.hide()
	is_closed = false
	_clean_up_nodes()
	
	focus_entered.connect(func():
		open()
		_ready_updated()
		title_label.text = "%s Office" % ("Public" if Networking.network.is_public() else "Private")
	)
	focus_exited.connect(func(): close())
	
	_ready_updated()
	start_btn.finished.connect(_on_start)
	
	Networking.connection_closed.connect(func(): is_closed = true)
	Networking.connection_failed.connect(_on_connection_failed)
	Networking.connection_success.connect(_on_connected)
	Networking.player_connected.connect(_add_player)
	Networking.player_disconnected.connect(_remove_player)

func _clean_up_nodes():
	for c in player_container.get_children():
		c.free()
		
	delegator.nodes = [start_btn]

func _ready_updated():
	start_btn.disabled = not (is_owner and _is_everyone_ready())

func _is_everyone_ready():
	if player_container.get_child_count() == 0:
		return false
	
	for p in player_container.get_children():
		var row = p as OfficePlayerRow
		if not row.is_ready:
			return false
	return true

func _gui_input(event: InputEvent) -> void:
	if not handle_input(event):
		get_viewport().gui_release_focus()
		get_viewport().set_input_as_handled()
		_clean_up_nodes()

func handle_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		return false
	
	delegator.handle_event(event)
	return true

func _on_ready():
	var node = get_player_node(Networking.get_player_id())
	if node:
		node.toggle_ready()

func _on_start():
	if not is_owner or not is_multiplayer_authority(): return

	for p in player_container.get_children():
		var row = p as OfficePlayerRow
		if not row.is_ready:
			logger.warn("Cannot start game. Not all players are ready")
			return

	_start_game.rpc(GameManager.difficulty_level)

@rpc("call_local", "reliable")
func _start_game(level: DifficultyResource.Level):
	GameManager.start(GameManager.Mode.Multiplayer, GameManager.language, level)

func _on_connection_failed():
	failed_label.show()
	loading.hide()

func _on_connected():
	loading.hide()
	_clean_up_nodes()
	
func _add_player(id):
	var row = row_scene.instantiate()
	row.name = "%s" % Networking.get_player_id(id)
	row.ready_changed.connect(func(): _ready_updated())
	player_container.add_child(row, true)
	
	if id == multiplayer.get_unique_id():
		delegator.nodes.append(row)

func _remove_player(id):
	var row = get_player_node(id)
	if row:
		row.queue_free()
		
		if id == multiplayer.get_unique_id():
			delegator.nodes.erase(row)

func get_player_node(id):
	return player_container.get_node_or_null("%s" % id)
