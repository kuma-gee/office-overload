extends Node

signal lobby_loaded(data)

var logger = Logger.new("SteamLobby")

func _ready():
	SteamManager.init_successful.connect(func():
		SteamManager.steam.lobby_match_list.connect(_on_lobby_match_list)
	)

func load_lobbies():
	if not SteamManager.is_successful_initialized: return

	logger.info("Loading lobbies...")
	SteamManager.steam.addRequestLobbyListDistanceFilter(SteamManager.steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	SteamManager.steam.addRequestLobbyListFilterSlotsAvailable(1)
	SteamManager.steam.addRequestLobbyListResultCountFilter(30)
	SteamManager.steam.requestLobbyList()


func _on_lobby_match_list(these_lobbies: Array) -> void:
	var result = []
	var existing_names = []

	for this_lobby in these_lobbies:
		var id = this_lobby
		var mode = int(SteamManager.steam.getLobbyData(id, "mode"))
		var owner = SteamManager.steam.getLobbyOwner(id)
		var owner_name = SteamManager.steam.getFriendPersonaName(owner)
		var count = SteamManager.steam.getNumLobbyMembers(id)
		var max = SteamManager.steam.getLobbyMemberLimit(id)
		
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