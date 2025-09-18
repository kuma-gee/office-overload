extends WorkSpace

@export var start_doc: DocumentUI

@export var steam_label: Label
@export var buttons_container: Control
@export var private_office_btn: TypingButton
@export var public_office_btn: TypingButton
@export var join_office_btn: TypingButton
@export var public_checkbox: CheckBox
@export var title: Label

@export_category("Lobby")
@export var lobbies_paper: SteamLobbies
@export var office_doc: LobbyOffice

var is_starting := false

func _ready() -> void:
	title.text = GameManager.get_mode_title(GameManager.Mode.Multiplayer)
	steam_label.visible = not SteamManager.is_steam_available()
	buttons_container.visible = not steam_label.visible
	opening.connect(func(): start_doc.open(0.5))
	
	GameManager.game_started.connect(func(): is_starting = true)
	
	private_office_btn.finished.connect(func(): _open_office(false))
	public_office_btn.finished.connect(func(): _open_office(true))
	office_doc.focus_exited.connect(func():
		if not is_starting:
			Networking.reset_network()
			office_doc.is_owner = false
	)

	join_office_btn.finished.connect(func(): lobbies_paper.grab_focus())
	lobbies_paper.requested_join.connect(func(id):
		get_viewport().gui_release_focus()
		Networking.join_game(id)
		office_doc.grab_focus()
	)

func _open_office(public: bool):
	Networking.host_game({"public": public})
	office_doc.is_owner = true
	office_doc.grab_focus()
