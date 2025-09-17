extends Node

signal init_successful()
signal steam_loaded()

var steam
var is_successful_initialized = false

var _logger = Logger.new("SteamManager")

func _ready():
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
	if not steam:
		steam = {}
	
	_load_steam()
	
func _load_steam():
	if not Env.is_steam():
		_logger.info("Steam is disabled")
		steam_loaded.emit()
		return
	
	var init = steam.steamInit(Build.STEAM_APP, false)
	is_successful_initialized = init
	_logger.info("Steam App %s initialized? %s" % [Build.STEAM_APP, init])
	
	if is_successful_initialized:
		_logger.debug("Logged in as %s(%s)" % [SteamManager.get_username(), SteamManager.get_steam_id()])
		init_successful.emit()
		GameManager.exiting_game.connect(func(): steam.steamShutdown())
	
	steam_loaded.emit()

func _process(_delta):
	if is_successful_initialized:
		steam.run_callbacks()

func is_steam_available():
	return is_successful_initialized and Env.is_steam()

func get_username():
	return steam.getPersonaName()

func get_steam_username(id: int):
	return steam.getFriendPersonaName(id)

func get_steam_id():
	if not is_steam_available(): return 0
	return steam.getSteamID()

func set_rich_presence(token: String, dict: Dictionary = {}) -> void:
	steam.clearRichPresence()
	
	if token == "":
		return
	
	for key in dict:
		var s = steam.setRichPresence(key, "%s" % dict[key])
		_logger.debug("Setting rich presence arg \"%s\" to \"%s\": %s" % [key, dict[key], s])
	
	var setting = steam.setRichPresence("steam_display", token)
	_logger.debug("Setting rich presence display to %s: %s" % [token, setting])
