class_name Multiplayer
extends StartView

@export var host_paper: PlayerPaper
@export var join_paper: PlayerPaper

func _ready():
	Networking.player_connected.connect(func(id): host_paper.update_values.rpc_id(id))

func open():
	super.open()

	if not Networking.is_network_connected():
		setup_host()
	else:
		setup_joined()

func setup_host():
	Networking.host_game()
	delegator.nodes = [host_paper]
	host_paper.open(1.0)
	host_paper.update_values.rpc()

	join_paper.disable()

func setup_joined():
	delegator.nodes = [join_paper]
	join_paper.open(1.0)
	join_paper.update_values.rpc()

	host_paper.disable()

func close():
	super.close()
	Networking.reset_network()
