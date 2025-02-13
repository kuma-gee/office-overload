extends Node

const MAX_PEERS = 2
const DEFAULT_PORT = 14420

signal player_connected(id)
signal connection_failed()
signal connection_success()
signal disconnected()
signal server_created()

var network: Network
var logger = Logger.new("Networking")

func _ready():
	network = SteamNetwork.new(SteamManager.steam, DEFAULT_PORT, MAX_PEERS) if Env.is_steam() else ENetNetwork.new(DEFAULT_PORT, MAX_PEERS) 
	add_child(network)

	multiplayer.peer_connected.connect(func(id): player_connected.emit(id))

	# Client
	multiplayer.connected_to_server.connect(func():
		logger.info("Connection success")
		connection_success.emit()
	)
	multiplayer.connection_failed.connect(func():
		logger.info("Connection failed")
		connection_failed.emit()
	)
	multiplayer.server_disconnected.connect(func():
		reset_network()
		logger.info("Server disconnected")
		disconnected.emit()
	)

	# Server
	network.peer_created.connect(func(peer):
		multiplayer.multiplayer_peer = peer
		server_created.emit()
	)
	network.connection_failed.connect(func(): connection_failed.emit())

func host_game():
	network.host_game()

func join_game(id):
	network.join_game(id)

func is_network_connected():
	return multiplayer.multiplayer_peer != null

func reset_network():
	logger.info("Connection reset")
	network.close_game()
