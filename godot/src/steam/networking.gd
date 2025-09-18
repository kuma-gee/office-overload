extends Node

const MAX_PEERS = 5
const DEFAULT_PORT = 14420

signal player_connected(id)
signal player_disconnected(id)
signal connection_failed()
signal connection_success()
signal connection_closed()

signal game_error(err)

var network := SteamNetwork.new(DEFAULT_PORT, MAX_PEERS)
var logger = Logger.new("Networking")

var players := {}
var is_connecting := false
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

	network.connection_success.connect(func(peer):
		multiplayer.multiplayer_peer = peer
		if is_status_connected():
			_connected()
	)
	network.connection_failed.connect(func(): connection_failed.emit())
	
	# Only called by clients
	multiplayer.connected_to_server.connect(func(): _connected())
	multiplayer.connection_failed.connect(func(): _failed())
	multiplayer.server_disconnected.connect(func(): _disconnected())

func _connected():
	logger.info("Connection success")
	connection_success.emit()
	_player_connected(multiplayer.get_unique_id())

func _failed():
	logger.info("Connection failed")
	connection_failed.emit()

func _disconnected():
	reset_network()
	logger.info("Server disconnected")
	connection_closed.emit()

func _player_connected(id):
	logger.info("Client Connected: %s" % id)
	players[id] = network.get_player_id(id)
	player_connected.emit(id)

func _player_disconnected(id):
	logger.info("Client Disconnected: %s" % id)
	players.erase(id)
	player_disconnected.emit(id)

func host_game(x):
	network.host_game(x)
	logger.info("Hosting server")

func join_game(id):
	network.join_game(id)
	logger.info("Joining server %s" % id)

func is_public():
	return network.is_public()

func is_status_connected():
	return multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED

func get_player_count() -> int:
	return players.size()

func get_players():
	return players.keys()

func get_player_id(id = multiplayer.get_unique_id()):
	if not id in players: return null
	return players[id]

func get_player_name(id):
	var player_id = get_player_id(id)
	return network.get_player_name(player_id)

func close_network():
	logger.info("Disable any further connections")
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.refuse_new_connections = true
	network.close_game()

func reset_network():
	logger.info("Reset network")
	close_network()
	multiplayer.multiplayer_peer = null
	players = {}
