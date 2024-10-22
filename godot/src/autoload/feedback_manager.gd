extends Node

const URL = "https://api.kuma-gee.com/feedback"

signal request_running()
signal request_failed()
signal request_successful()
signal request_throttled(time_left: float)

@export var enable := true

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var throttle_timer: Timer = $ThrottleTimer

var _logger = Logger.new("FeedbackManager")
var _is_sending := false

func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)
	request_successful.connect(func(): throttle_timer.start())

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	_logger.info("Feedback request finished with %s and status %s" % [result, response_code])
	_is_sending = false
	
	if result == HTTPRequest.Result.RESULT_SUCCESS and response_code == 200:
		request_successful.emit()
	else:
		request_failed.emit()

func send_feedback(text: String):
	if not enable:
		_logger.warn("Sending feedback is not enabled for this game")
		return
	
	if not throttle_timer.is_stopped():
		request_throttled.emit(throttle_timer.time_left)
		_logger.info("Please wait %s seconds before sending another feedback" % throttle_timer.time_left)
		return
	
	var res = http_request.request(URL, [], HTTPClient.METHOD_POST, JSON.stringify({
		"text": text,
		"game": ProjectSettings.get_setting("application/config/name"),
		"version": Build.VERSION,
		"sha": Build.GIT_SHA,
		"demo": Env.is_demo(),
		"platform": OS.get_name(),
	}))

	if res != OK:
		_logger.info("Failed to send feedback request: %s" % res)
		request_failed.emit()
	else:
		request_running.emit()
		_is_sending = true

func get_time_until_next_feedback():
	return throttle_timer.time_left
