class_name CacheProperties
extends Node

@export var properties: Array[String]
@export var node: Node

var logger = Logger.new("SaveProperties")


func _ready():
	add_to_group(CacheManager.PERSIST_GROUP)


func save_data():
	var data = {}
	for prop in properties:
		data[prop] = node.get(prop)

	logger.debug("Save for %s: %s" % [node.get_path(), str(data)])
	return data


func load_data(data: Dictionary):
	logger.debug("Load for %s: %s" % [node.get_path(), str(data)])
	for prop in data:
		node.set(prop, data[prop])
