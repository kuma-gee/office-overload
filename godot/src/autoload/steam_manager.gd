extends Node

signal steam_status_changed()

const ACHIEVEMENT = {CEO = "CEO"}

var steam
var _logger = Logger.new("SteamManager")

var achievements: Dictionary = {}
var steam_update_timer: Timer
var is_successful_initialized = false

func _ready():
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
	
	if not steam:
		steam = {}
		return
	
	steam_update_timer = Timer.new()
	steam_update_timer.one_shot = true
	steam_update_timer.autostart = false
	add_child(steam_update_timer)
	
	steam_update_timer.timeout.connect(func():
		if steam.storeStats():
			_logger.info("Stats updated")
		else:
			_logger.warn("Failed to update stats")
	)

	_load_steam()
	
func _load_steam():
	if not Env.is_steam():
		_logger.info("Steam is disabled")
		return
	
	#if Env.is_prod():
		#if not Steam.restartAppIfNecessary(APP_ID):
			#_logger.warn("Failed to restart app through steam. It might already be started through steam.")
	
	# This is not always called. Skipped if no diff to local storage?
	#Steam.current_stats_received.connect(_on_steam_stats_ready)
	steam.user_achievement_stored.connect(_on_achievement_stored)
	
	var id = Build.STEAM_APP
	var init = steam.steamInit(true, id)
	is_successful_initialized = init.status == 1
	_logger.info("Steam initialized? %s" % init)
	steam_status_changed.emit()
	
	if check_steam_available():
		var stats_status = steam.requestCurrentStats()
		_logger.info("Requesting steam stats: %s" % stats_status)
		_sync_achievements()

	if is_successful_initialized:
		GameManager.exiting_game.connect(func(): steam.steamShutdown())
		_connect_leaderboard_signals()

func _process(delta):
	if is_successful_initialized:
		steam.run_callbacks()

func check_steam_available():
	if is_successful_initialized: return true
	
	return false

#############
## Profile ##
#############

func get_username():
	return steam.getPersonaName()

func get_steam_username(id: int):
	return steam.getFriendPersonaName(id)

func get_steam_id():
	return steam.getSteamID()

#################
## Leaderboard ##
#################

const DEMO_LEADERBOARD = "demo_mode"
const ENDLESS_LEADERBOARD = "endless_mode"
const STORY_LEADERBOARD = "story_mode"
const TIMED_LEADERBOARD = "timed_mode"

signal leaderboard_loaded(board: String, result: Array)
signal leaderboard_uploaded(board: String, score: Dictionary)
signal leaderboard_handler_loaded()

var leaderboard_handles: Dictionary = {}
var loading_handles := []
var last_result = []
var is_uploading := false
var handler_loaded := false
var score_range := 30

func _connect_leaderboard_signals():
	steam.leaderboard_find_result.connect(_on_leaderboard_find_result)
	steam.leaderboard_score_uploaded.connect(_on_leaderboard_score_uploaded)
	steam.leaderboard_scores_downloaded.connect(_on_leaderboard_scores_downloaded)
	_load_all_leaderboard()

func _load_all_leaderboard():
	if Env.is_demo():
		loading_handles = [DEMO_LEADERBOARD]
	else:
		loading_handles = [ENDLESS_LEADERBOARD, STORY_LEADERBOARD, TIMED_LEADERBOARD]
	
	_load_leaderboard_handle()

func _load_leaderboard_handle():
	if loading_handles.is_empty():
		handler_loaded = true
		leaderboard_handler_loaded.emit()
		return
	
	_logger.info("Loading steam leaderboard for %s" % [loading_handles[0]])
	steam.findLeaderboard(loading_handles[0])

func _on_leaderboard_find_result(handle: int, found: int) -> void:
	if found == 1 and not loading_handles.is_empty():
		var board = loading_handles.pop_front()
		leaderboard_handles[board] = handle
		_logger.info("Leaderboard %s found: %s" % [board, handle])
	else:
		_logger.warn("No handle was found or loading handles empty: %s, %s, %s" % [loading_handles, handle, found])
		loading_handles.pop_front()
	
	_load_leaderboard_handle()

func upload_score(board: String, score: int, details: String, keep_best = true):
	if check_steam_available():
		if board in leaderboard_handles:
			var detail_array = var_to_bytes(details).to_int32_array()
			steam.uploadLeaderboardScore(score, keep_best, detail_array, leaderboard_handles[board])
			_logger.info("Uploading score %s to %s with details of size %s" % [score, board, detail_array.size()])
			is_uploading = true
		else:
			_logger.warn("Leaderboard %s hasn't been loaded" % board)
	else:
		_logger.warn("Steam not available to upload scores")

func _on_leaderboard_score_uploaded(success: int, this_handle: int, this_score: Dictionary) -> void:
	var board = _find_leaderboard_for_handle(this_handle)
	is_uploading = false
	if success == 1:
		_logger.info("Successfully uploaded scores!")
		leaderboard_uploaded.emit(board, this_score)
	else:
		_logger.error("Failed to upload scores!")
		leaderboard_uploaded.emit(board, null)
	

func load_score(board: String, type: int):
	if not check_steam_available():
		_logger.warn("Steam is not available to load leaderboard scores")
		return []

	if not board in leaderboard_handles:
		_logger.warn("Leaderboard handle for %s not loaded" % board)
		return []

	if is_uploading:
		_logger.info("Awaiting score upload before fetching score for %s" % board)
		await leaderboard_uploaded
	
	if not handler_loaded:
		_logger.info("Awaiting leaderboard handles")
		await leaderboard_handler_loaded
	
	var start = 1
	var end = score_range
	if type == steam.LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER:
		var mid = score_range/2
		start = -mid
		end = mid-1
	
	steam.downloadLeaderboardEntries(start, end, type, leaderboard_handles[board])
	await leaderboard_loaded

	_logger.info("Loaded Leaderboard: %s" % [last_result.size()])
	return last_result

func _on_leaderboard_scores_downloaded(message: String, this_leaderboard_handle: int, result: Array) -> void:
	_logger.debug("Scores downloaded message: %s" % message)
	
	var board = _find_leaderboard_for_handle(this_leaderboard_handle)
	if not board:
		_logger.warn("Leaderboard name not found for handle %s" % this_leaderboard_handle)
	
	last_result = result
	leaderboard_loaded.emit(board, result)

func _find_leaderboard_for_handle(handle: int):
	for k in leaderboard_handles.keys():
		if leaderboard_handles[k] == handle:
			return k
	return null

##################
## Achievements ##
##################

func unlock_achievement(achieve: String):
	if achieve in achievements and achievements[achieve]:
		_logger.debug("Achievement %s has already been unlocked" % achieve)
		return
	
	achievements[achieve] = true
	
	if steam.setAchievement(achieve):
		_logger.info("Unlocked steam achievement: %s" % achieve)
	else:
		_logger.warn("Failed to set achievement: %s" % achieve)
	
	steam_update_timer.start(0.2)

func _sync_achievements():
	for key in ACHIEVEMENT.keys():
		var achieve = ACHIEVEMENT[key]
		achievements[achieve] = _get_achievement(achieve)
		_logger.info("Steam Achievement %s: %s" % [achieve, achievements[achieve]])
	_logger.info("Synced Achievements: %s" % achievements)

func _get_achievement(value: String) -> bool:
	var this_achievement: Dictionary = steam.getAchievement(value)

	# Achievement exists
	if this_achievement['ret']:
		return this_achievement['achieved']

	return false

func _on_achievement_stored(app_id: int, group_achieve: bool, achieve_name: String, progress: int, max_progress: int):
	_logger.info("Achievement %s has been successfully stored" % achieve_name)
