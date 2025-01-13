extends Node

signal initialized()

const CLOUD_FILE = "save.dat"

var logger := Logger.new("SteamCloud")
var is_uploading := false

func _ready() -> void:
	SteamManager.steam_loaded.connect(func():
		if SteamManager.is_steam_available():
			download_from_cloud()
			SteamManager.steam.file_write_async_complete.connect(_on_file_write_async_complete)
			SteamManager.steam.file_read_async_complete.connect(_on_file_read_async_complete)
		else:
			initialized.emit()
	)

func _on_file_write_async_complete(result: int):
	if result == Steam.RESULT_OK:
		logger.info("File upload completed successfully")
	else:
		logger.error("Failed to write file to steam cloud. Error code: %d" % result)

	var quota = get_used_quota()
	logger.info("Cloud storage used: %f" % quota)
	if quota > 0.9:
		logger.warn("Cloud storage is almost full. Contacting the dev via the feedback form")
		FeedbackManager.send_feedback("Steam cloud storage is almost full for a user. Used: %f" % quota, true)

	is_uploading = false

func _on_file_read_async_complete(dict: Dictionary):
	if dict["result"] == Steam.RESULT_OK and dict["complete"]:
		var data = dict["buffer"] as PackedByteArray
		var file = FileAccess.open(_get_save_file(), FileAccess.WRITE)
		if file:
			file.store_buffer(data)
			logger.info("File download completed successfully")
		else:
			logger.error("Failed to open file for writing")
	else:
		logger.error("Failed to read file from steam cloud. Error code: %d, %s" % [dict["result"], dict["complete"]])
	
	initialized.emit()

func _get_save_file():
	return SaveManager.SAVE_FILE % 0

func is_steam_cloud_enabled():
	return SteamManager.is_steam_available() and SteamManager.steam.isCloudEnabledForAccount() and SteamManager.steam.isCloudEnabledForApp()

func get_used_quota():
	var data = SteamManager.steam.getQuota()
	var total = data["total_bytes"]
	var available = data["available_bytes"]
	return (total - available) / float(total)

func download_from_cloud():
	if not is_steam_cloud_enabled():
		logger.warn("Steam not initialized.")
		initialized.emit()
		return
		
	if not SteamManager.steam.fileExists(CLOUD_FILE):
		logger.warn("No save file found in the cloud.")
		initialized.emit()
		return

	logger.info("Downloading save file from steam cloud")
	SteamManager.steam.fileReadAsync(CLOUD_FILE, 0, SteamManager.steam.getFileSize(CLOUD_FILE))

func upload_to_cloud():
	if not is_steam_cloud_enabled():
		logger.warn("Steam not initialized.")
		return
	
	var file = _get_save_file()
	if not FileAccess.file_exists(file):
		logger.warn("Save files does not exist.")
		return
	
	if not SteamManager.steam.fileExists(CLOUD_FILE):
		_upload_file(file)
	else:
		var last_modified = FileAccess.get_modified_time(file)
		if last_modified == 0:
			logger.warn("Failed to get last modified time of save file. Not uploading current save file.")
			return
		
		var cloud_timestamp = SteamManager.steam.getFileTimestamp(file)
		if last_modified == cloud_timestamp:
			logger.info("No changes has been made since the last sync")
			return
			
		if last_modified > cloud_timestamp:
			_upload_file(file)
		else:
			logger.debug("Local file is older than the current uploaded save file. Skipping upload")

func _upload_file(file: String):
	logger.info("Uploading %s to steam cloud" % file)
	SteamManager.steam.fileWrite(CLOUD_FILE, FileAccess.get_file_as_bytes(file))
	logger.info("File upload completed successfully")
