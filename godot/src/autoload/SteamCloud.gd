extends Node

signal initialized()

const CLOUD_FILE = "save.dat"

var steam
var logger := Logger.new("SteamCloud")
var is_uploading := false

func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		initialized.emit()
		logger.debug("Steam single does not exist")
		return

	steam = Engine.get_singleton("Steam")
	if not is_steam_cloud_enabled():
		initialized.emit()
		logger.debug("Steam cloud is not enabled")
		return
	
	if SteamManager.check_steam_available():
		download_from_cloud()
	
	SteamManager.steam_status_changed.connect(func():
		if SteamManager.check_steam_available():
			download_from_cloud()
	)

	steam.file_write_async_complete.connect(_on_file_write_async_complete)
	steam.file_read_async_complete.connect(_on_file_read_async_complete)

func _on_file_write_async_complete(result: int):
	if result == Steam.RESULT_OK:
		logger.info("File upload completed successfully")
	else:
		logger.error("Failed to write file to steam cloud. Error code: %d" % result)

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
	return steam and steam.isCloudEnabledForAccount() and steam.isCloudEnabledForApp() and SteamManager.is_successful_initialized

func download_from_cloud():
	if not is_steam_cloud_enabled():
		logger.warn("Steam not initialized.")
		initialized.emit()
		return
		
	if not steam.fileExists(CLOUD_FILE):
		logger.warn("No save file found in the cloud.")
		initialized.emit()
		return

	logger.info("Downloading save file from steam cloud")
	steam.fileReadAsync(CLOUD_FILE, 0, steam.getFileSize(CLOUD_FILE))

func upload_to_cloud():
	if not is_steam_cloud_enabled():
		logger.warn("Steam not initialized.")
		return
	
	var file = _get_save_file()
	if not FileAccess.file_exists(file):
		logger.warn("Save files does not exist.")
		return
	
	if not steam.fileExists(CLOUD_FILE):
		_upload_file(file)
	else:
		var last_modified = FileAccess.get_modified_time(file)
		if last_modified == 0:
			logger.warn("Failed to get last modified time of save file. Not uploading current save file.")
			return
		
		var cloud_timestamp = steam.getFileTimestamp(file)
		if last_modified == cloud_timestamp:
			logger.info("No changes has been made since the last sync")
			return
			
		if last_modified > cloud_timestamp:
			_upload_file(file)
		else:
			logger.debug("Local file is older than the current uploaded save file. Skipping upload")

func _upload_file(file: String):
	logger.info("Uploading %s to steam cloud" % file)
	steam.fileWrite(CLOUD_FILE, FileAccess.get_file_as_bytes(file))
	logger.info("File upload completed successfully")
