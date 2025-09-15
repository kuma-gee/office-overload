extends WorkSpace

@export var start_doc: DocumentUI

@export var steam_label: Label
@export var buttons_container: Control
@export var open_office_btn: TypingButton
@export var join_office_btn: TypingButton
@export var public_checkbox: CheckBox

@export_category("Lobby")
@export var lobbies_paper: SteamLobbies
@export var office_doc: LobbyOffice

func _ready() -> void:
	steam_label.visible = not SteamManager.is_steam_available()
	buttons_container.visible = not steam_label.visible
	opening.connect(func(): start_doc.open(0.5))
	
	open_office_btn.finished.connect(func():
		Networking.network.host_game(public_checkbox.button_pressed)
		office_doc.is_owner = true
		office_doc.grab_focus()
	)
	
	office_doc.focus_exited.connect(func():
		Networking.reset_network()
		office_doc.is_owner = false
	)

	join_office_btn.finished.connect(func(): lobbies_paper.grab_focus())
	lobbies_paper.requested_join.connect(func(id):
		get_viewport().gui_release_focus()
		Networking.join_game(id)
		office_doc.grab_focus()
	)
