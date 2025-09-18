class_name SteamLobbyRow
extends Control

signal finished()

@export var typing_label: TypedWord
@export var lobby_label: Label
@export var count_label: Label

var word := ""
var lobby: Dictionary

func _ready() -> void:
	typing_label.type_finish.connect(func(): finished.emit())
	typing_label.word = word
	lobby_label.text = "%s's Lobby" % SteamManager.get_steam_username(int(lobby["creator"]))
	count_label.text = "%s / %s" % [lobby["count"], lobby["max"]]

func get_label():
	return typing_label
