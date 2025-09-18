class_name SteamNetwork
extends Node

signal connection_success(peer)
signal connection_failed

var owner_id := -1
var lobby_id := -1
var lobby_type := 0

var max_peers := 5
var port := 14420
var steam = {}
var multiplayer_class = "SteamMultiplayerPeer"
var logger = Logger.new("SteamNetwork")

var players := {}
var lobby_data := {}

func _init(p: int, max_p: int) -> void:
	port = p
	max_peers = max_p

func _ready():
	SteamManager.init_successful.connect(func():
		steam = Engine.get_singleton("Steam")
		steam.lobby_created.connect(_on_lobby_created)
		steam.lobby_joined.connect(_on_lobby_joined)
		steam.join_requested.connect(_on_lobby_join_requested)
	)
	
func get_player_id(id):
	return multiplayer.multiplayer_peer.get_steam64_from_peer_id(id)

func host_game(data = {}):
	if not steam: return
	lobby_type = steam.LOBBY_TYPE_FRIENDS_ONLY
	if "public" in data and data["public"]:
		lobby_type = steam.LOBBY_TYPE_PUBLIC
	
	lobby_data = data
	steam.createLobby(lobby_type, max_peers)

func is_public():
	return lobby_type == steam.LOBBY_TYPE_PUBLIC

func join_game(id):
	if not steam: return
	lobby_id = id
	steam.joinLobby(lobby_id)

func close_game():
	if not steam or lobby_id == 0: return
	steam.leaveLobby(lobby_id)
	lobby_id = 0
	lobby_type = 0

func _create_server():
	var peer = _create_multiplayer_class()
	if peer:
		peer.create_host(port)
		connection_success.emit(peer)

func _create_client(owner_id):
	owner_id = owner_id
	var peer = _create_multiplayer_class()
	if peer:
		peer.create_client(owner_id, port)
		connection_success.emit(peer)

func _create_multiplayer_class():
	if not ClassDB.class_exists(multiplayer_class):
		logger.warn("Multiplayer class %s does not exist" % multiplayer_class)
		return
	
	return ClassDB.instantiate(multiplayer_class)

func _on_lobby_join_requested(_lobby_id: int, friend_id: int):
	var OWNER_NAME = steam.getFriendPersonaName(friend_id)
	logger.info("Joining "+str(OWNER_NAME)+"'s lobby...")
	join_game(_lobby_id)
	
func _on_lobby_created(_connect: int, _lobby_id: int):
	if _connect == 1:
		lobby_id = _lobby_id
		steam.setLobbyData(_lobby_id, "mode", str(lobby_type))
		steam.setLobbyData(_lobby_id, "creator", str(SteamManager.get_steam_id()))
		
		logger.debug("Setting lobby data: %s" % lobby_data)
		for key in lobby_data:
			steam.setLobbyData(_lobby_id, key, str(lobby_data[key]))
		
		logger.info("Lobby Created: %s" % _lobby_id)
		_create_server()
	else:
		logger.info("Error creating lobby")
		connection_failed.emit()

func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == 1:
		var id = steam.getLobbyOwner(_lobby_id)
		if id != steam.getSteamID():
			lobby_id = _lobby_id
			lobby_type = int(steam.getLobbyData(_lobby_id, "mode"))
			logger.info("Joined Lobby: %s" % lobby_type)
			_create_client(id)
	else:
		var FAIL_REASON: String
		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		
		connection_failed.emit()
		logger.info("Failed to join lobby: %s" % [FAIL_REASON])
		
