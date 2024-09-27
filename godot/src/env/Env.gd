extends Node

const UNLOCK_HASH = "06da2286fd35308a48d6c0e2f512dc82005f17f2a19cd73b4a5a1c0dc259289c"

var log_level := Logger.Level.DEBUG
var version := Build.VERSION
var editor_is_prod := false

var _logger := Logger.new("Env")
var _live := false
var _enable_steam := false

func _ready():
	if is_prod():
		log_level = Logger.Level.INFO
	
	var args = _args_dictionary()
	if "live" in args:
		_live = _get_hash(args["live"]) == UNLOCK_HASH
	if args.has("steam"):
		_enable_steam = true
	if args.has("debug"):
		log_level = Logger.Level.DEBUG
	
	_logger.info("Running version %s on %s: %s" % [version, OS.get_name(), {
		"demo": is_demo(),
		"steam": is_steam(),
		"log_level": Logger.Level.keys()[log_level],
	}])

func is_editor():
	return OS.is_debug_build()

func is_prod() -> bool:
	return not is_editor() or editor_is_prod

func is_web() -> bool:
	return OS.has_feature("web")

func is_demo() -> bool:
	return not _live and is_prod()

func is_steam() -> bool:
	return _enable_steam

func is_debug_level():
	return log_level == Logger.Level.DEBUG

func _args_dictionary():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			arguments[argument.lstrip("--")] = ""

	return arguments

func _get_hash(s: String):
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(s.to_utf8_buffer())
	var res = ctx.finish()
	return res.hex_encode()
