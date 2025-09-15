class_name SteamLobbies
extends FocusedDialog

signal requested_join(id)

@export var id_length := 4
@export var container: Control
@export var button_scene: PackedScene
@export var scroll_container: TypedScrollContainer
@export var empty_label: Label
@export var loading_label: Control

func _ready() -> void:
	super()
	
	focus_entered.connect(func():
		empty_label.hide()
		loading_label.show()
		Networking.network.load_lobbies()
	)
	Networking.network.lobby_loaded.connect(_add_lobbies)
	
func _add_lobbies(lobbies: Array):
	scroll_container.reset()
	for c in container.get_children():
		c.queue_free()
		delegator.nodes.erase(c)

	scroll_container.update(lobbies)
	empty_label.visible = lobbies.is_empty()
	loading_label.hide()
	
	if lobbies.is_empty():
		return

	scroll_container.active()
	for lobby in lobbies:
		var alphabet_id = _generate_unique_id(lobby["id"])
		var btn = button_scene.instantiate() as SteamLobbyRow
		btn.word = alphabet_id
		btn.lobby = lobby
		btn.finished.connect(func(): requested_join.emit(lobby["id"]))
		container.add_child(btn)
		delegator.nodes.append(btn)

func _generate_unique_id(lobby_id: int) -> String:
	var alphabet := "ABCDEFGHILMNOPQRSTUVWXYZ" # Exclude J/K for scrolling
	var unique_id := ""
	var id := lobby_id

	while unique_id.length() < id_length:
		unique_id = alphabet[id % alphabet.length()] + unique_id
		id = id / alphabet.length()

	# Pad with 'A' if the generated ID is shorter than id_length
	#while unique_id.length() < id_length:
		#unique_id = "A" + unique_id

	# Truncate if the generated ID is longer than id_length
	#if unique_id.length() > id_length:
		#unique_id = unique_id.substr(unique_id.length() - id_length, id_length)

	return unique_id
