extends Node

const LOCAL_FORMAT = "./%s"
const RES_FORMAT = "res://%s"

var _logger = Logger.new("DataLoader")
var items = []

func _ready() -> void:
	var trans = Translation.new()
	for line in load_csv("translations.csv", ["key", "value"]):
		trans.add_message(line["key"], line["value"])
	TranslationServer.add_translation(trans)

func load_file(path: String):
	var local = LOCAL_FORMAT % path
	if FileAccess.file_exists(local):
		_logger.info("Loading local file %s" % local)
		return FileAccess.open(local, FileAccess.READ)
	
	var res = RES_FORMAT % path
	_logger.info("Loading default word file %s" % res)
	return FileAccess.open(res, FileAccess.READ)

func load_csv(path: String, column_names: Array[String]) -> Array[Dictionary]:
	var file = load_file(path)
	if not file:
		print("Failed to open file %s" % path)
		return []
	
	var data: Array[Dictionary] = []
	while not file.eof_reached():
		var item = {}
		var parts = file.get_csv_line()
		if parts.is_empty() or (parts.size() == 1 and parts[0] == ""):
			continue

		for i in range(column_names.size()):
			if parts.size() <= i:
				break

			item[column_names[i]] = parts[i].strip_edges()
		
		if not item.is_empty():
			data.append(item)

	return data
