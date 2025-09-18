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
	SteamManager.steam.addRequestLobbyListResultCountFilter(20)
	SteamManager.steam.requestLobbyList()


func _on_lobby_match_list(these_lobbies: Array) -> void:
	var result = []
	var existing_names = []

	for id in these_lobbies:
		var count = SteamManager.steam.getNumLobbyMembers(id)
		var max = SteamManager.steam.getLobbyMemberLimit(id)
		
		var data = {
			"id": id,
			"count": count,
			"max": max,
		}
		
		var lobby_data = Steam.getAllLobbyData(id)
		for key in lobby_data:
			var d = lobby_data[key]
			data[d["key"]] = d["value"]

		result.append(data)
	
	logger.info("Loaded %s lobbies" % result.size())
	lobby_loaded.emit(result)
