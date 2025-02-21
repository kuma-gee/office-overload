class_name SaveManager
extends Node

const SAVES_FOLDER = "user://saves"
const SAVE_FILE = SAVES_FOLDER + "/save_%s.dat"

var logger = Logger.new("SaveManager")


func _ready():
	if not DirAccess.dir_exists_absolute(SAVES_FOLDER):
		DirAccess.make_dir_absolute(SAVES_FOLDER)

func save_to_slot(slot: int, data):
	var file_name = SAVE_FILE % slot
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	if file == null:
		logger.error("Failed to save data to %s: %s" % [file_name, FileAccess.get_open_error()])
	else:
		file.store_var(data)
		logger.debug("Save to %s: %s" % [file_name, str(data)])
	file.close()

func load_from_slot(slot: int):
	var file_name = SAVE_FILE % slot
	var file = FileAccess.open(file_name, FileAccess.READ)
	var data
	if file == null:
		logger.info("No save file to load from at %s" % [file_name])
	else:
		data = file.get_var()
		if data:
			logger.debug("Load from %s: %s" % [file_name, str(data)])
		file.close()

	return data


func is_slot_saved(slot: int):
	var file_name = SAVE_FILE % slot
	return FileAccess.file_exists(file_name)
