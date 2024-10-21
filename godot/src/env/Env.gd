extends Node

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
	print(args)
	
	if args.has("debug"):
		log_level = Logger.Level.DEBUG
	if args.has("steam"):
		_enable_steam = true
	if "live" in args:
		var hash = args["live"].sha256_text()
		_logger.debug("Using hash %s" % hash)
		_live = hash == Build.GAME_HASH
	
	_logger.info("Running version %s (%s) on %s: %s" % [version, Build.GIT_SHA, OS.get_name(), {
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
