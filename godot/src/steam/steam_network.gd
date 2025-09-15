class_name SteamNetwork
extends Node

signal connection_success(peer)
signal connection_failed
signal connection_closed

signal player_joined(id)
signal player_left(id)
signal lobby_loaded(data)

var owner_id := -1
var lobby_id := -1
var lobby_type := 0

var max_peers := 5
var port := 14420
var steam = {}
var multiplayer_class = "SteamMultiplayerPeer"
var logger = Logger.new("SteamNetwork")

var players := {}

func _init(p: int, max_p: int) -> void:
	port = p
	max_peers = max_p

func _ready():
	SteamManager.init_successful.connect(func():
		steam = Engine.get_singleton("Steam")
		steam.join_requested.connect(_on_lobby_join_requested)
		steam.lobby_created.connect(_on_lobby_created)
		steam.lobby_joined.connect(_on_lobby_joined)
		steam.lobby_match_list.connect(_on_lobby_match_list)
	)
	
func _player_connected(id):
	players[id] = get_player_id(id)
	player_joined.emit(id)
	logger.info("Client Connected: %s" % id)

func _player_disconnected(id):
	players.erase(id)
	player_left.emit(id)
	logger.info("Client Disconnected: %s" % id)
	
func get_player_id(id):
	return multiplayer.multiplayer_peer.get_steam64_from_peer_id(id)

func host_game(public := false):
	if not steam: return
	lobby_type = steam.LOBBY_TYPE_FRIENDS_ONLY if not public else steam.LOBBY_TYPE_PUBLIC
	steam.createLobby(lobby_type, max_peers)

func is_public():
	return lobby_type == steam.LOBBY_TYPE_PUBLIC

func join_game(id):
	if not steam: return
	lobby_id = id
	steam.joinLobby(lobby_id)

func load_lobbies():
	if not steam: return

	steam.addRequestLobbyListDistanceFilter(steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	steam.addRequestLobbyListFilterSlotsAvailable(1)
	steam.addRequestLobbyListResultCountFilter(30)
	steam.requestLobbyList()
	logger.info("Loading lobbies...")

func close_game():
	if not steam or lobby_id == 0: return
	steam.leaveLobby(lobby_id)
	lobby_id = 0
	lobby_type = 0

func _create_server():
	SteamMultiplayerPeer
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
		logger.info("Lobby Created: %s" % _lobby_id)
		_create_server()
	else:
		connection_failed.emit()
		logger.info("Error creating lobby")

func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == 1:
		var id = steam.getLobbyOwner(_lobby_id)
		if id != steam.getSteamID():
			lobby_id = _lobby_id
			logger.info("Joined Lobby")

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
		
func _on_lobby_match_list(these_lobbies: Array) -> void:
	var result = []
	var existing_names = []

	for this_lobby in these_lobbies:
		var id = this_lobby
		var mode = int(steam.getLobbyData(id, "mode"))
		var owner = steam.getLobbyOwner(id)
		var owner_name = steam.getFriendPersonaName(owner)
		var count = steam.getNumLobbyMembers(id)
		var max = steam.getLobbyMemberLimit(id)
		
		var data = {
			"id": id,
			"mode": mode,
			"owner": owner,
			"owner_name": owner_name,
			"count": count,
			"max": max,
		}
		
		# Possible?
		if owner_name in existing_names:
			logger.warn("Skipping duplicate lobby from %s" % owner_name)
			continue

		existing_names.append(owner_name)
		result.append(data)
	
	logger.info("Loaded %s lobbies" % result.size())
	lobby_loaded.emit(result)
