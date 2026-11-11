extends Node

signal achievements_synched()

const ACHIEVEMENT = {
	CEO = "CEO", # CEO
	MANAGER = "MANAGER", # MGR
	SENIOR = "SENIOR", # SR
	JUNIOR = "JUNIOR", # JR
	FIRST_DAY = "FIRST_DAY", # New Hire
	WORKAHOLIC = "WORKAHOLIC", # Workaholic
	OVERTIME = "OVERTIME", # Overtime
	RESIGNED = "RESIGNED", # Two Weeks' Notice
	BURNOUT = "BURNOUT", # Burnout
	FIRED = "FIRED", # You're Fired!
	FLAWLESS = "FLAWLESS", # Flawless
	TOP_GRADE = "TOP_GRADE", # Straight A's
	COMBO_25 = "COMBO_25", # On a Roll
	WORDS_1K = "WORDS_1K", # Wordsmith
	WORDS_10K = "WORDS_10K", # Novelist
	FIRST_BUY = "FIRST_BUY", # Big Spender
	FULLY_EQUIPPED = "FULLY_EQUIPPED", # Office Upgrade
	RICH = "RICH", # Money Bags
	CAFFEINE = "CAFFEINE", # Caffeinated
}

var achievements: Dictionary = {}

var _steam_update_timer: Timer
var _logger = KumaLog.new("SteamAchievements")

func _ready():
	SteamManager.init_successful.connect(func():
		SteamManager.steam.user_achievement_stored.connect(_on_achievement_stored)
		_sync_achievements()

		_steam_update_timer = _create_one_shot_timer()
		_steam_update_timer.timeout.connect(func():
			if SteamManager.steam.storeStats():
				_logger.info("Stats updated")
			else:
				_logger.warn("Failed to update stats")
		)
	)

func _create_one_shot_timer():
	var timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	return timer

func unlock(achieve: String):
	if Env.is_demo():
		return
	
	if not SteamManager.is_steam_available():
		return
	
	if achieve in achievements and achievements[achieve]:
		_logger.debug("Achievement %s has already been unlocked" % achieve)
		return
	
	achievements[achieve] = true
	
	if SteamManager.steam.setAchievement(achieve):
		_logger.info("Unlocked steam achievement: %s" % achieve)
	else:
		_logger.warn("Failed to set achievement: %s" % achieve)
	
	if _steam_update_timer:
		_steam_update_timer.start(0.2)

func _sync_achievements():
	for key in ACHIEVEMENT.keys():
		var achieve = ACHIEVEMENT[key]
		achievements[achieve] = _get_achievement(achieve)
		_logger.info("Steam Achievement %s: %s" % [achieve, achievements[achieve]])
	
	_logger.info("Synced Achievements: %s" % achievements)
	achievements_synched.emit()

func _get_achievement(value: String) -> bool:
	var this_achievement: Dictionary = SteamManager.steam.getAchievement(value)

	if this_achievement['ret']:
		return this_achievement['achieved']

	return false

func _on_achievement_stored(app_id: int, group_achieve: bool, achieve_name: String, progress: int, max_progress: int):
	_logger.info("Achievement %s has been successfully stored" % achieve_name)
