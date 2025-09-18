extends Node

const MAX_PEERS = 5
const DEFAULT_PORT = 14420

signal player_list_changed()
signal player_connected(id)
signal player_disconnected(id)
signal connection_failed()
signal connection_success()
signal connection_closed()

signal game_error(err)

var network := SteamNetwork.new(DEFAULT_PORT, MAX_PEERS)
var logger = Logger.new("Networking")

var players := {}
var connected := false
var last_ping_time: float  

@rpc("any_peer")
func ping(target_id: int = multiplayer.get_unique_id(), iam_asking: bool = true):  
	if iam_asking:  
		last_ping_time = Time.get_unix_time_from_system()
		ping.rpc(target_id, false)  
	else:  
		var sender_id: int = multiplayer.get_remote_sender_id()
		print_ping.rpc_id(sender_id)

@rpc("any_peer")      
func print_ping():
	logger.debug("Ping delay for %s: %s" % [multiplayer.get_remote_sender_id(), Time.get_unix_time_from_system() - last_ping_time]) 

func _exit_tree():
	reset_network()

func _ready():
	add_child(network)

	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)

	# Only called by clients
	# multiplayer.connected_to_server.connect(func():
	# 	logger.info("Connection success")
	# 	connection_success.emit()
	# )
	multiplayer.connection_failed.connect(func():
		logger.info("Connection failed")
		connection_failed.emit()
	)
	multiplayer.server_disconnected.connect(func():
		reset_network()
		logger.info("Server disconnected")
		connection_closed.emit()
	)
	connection_success.connect(func(): connected = true)

	network.connection_success.connect(func(peer):
		multiplayer.multiplayer_peer = peer
		connection_success.emit()
		_player_connected(multiplayer.get_unique_id())
	)
	network.connection_failed.connect(func(): connection_failed.emit())

func host_game():
	network.host_game()
	logger.info("Hosting server")

func join_game(id):
	network.join_game(id)
	logger.info("Joining server %s" % id)

func has_network():
	return connected

func is_server():
	return has_network() and multiplayer.is_server()

func _player_connected(id):
	players[id] = network.get_player_id(id)
	player_list_changed.emit()
	player_connected.emit(id)
	logger.info("Client Connected: %s" % id)

func _player_disconnected(id):
	players.erase(id)
	player_list_changed.emit()
	player_disconnected.emit(id)
	logger.info("Client Disconnected: %s" % id)

func get_player_count() -> int:
	return players.size()

func get_player_id(id = multiplayer.get_unique_id()):
	if not id in players: return null
	return players[id]

func get_player_name(id):
	var player_id = get_player_id(id)
	return network.get_player_name(player_id)

func close_network():
	logger.info("Network closed")
	network.close_game()

func reset_network():
	logger.info("Connection reset")
	close_network()
	multiplayer.multiplayer_peer = null
	players = {}
