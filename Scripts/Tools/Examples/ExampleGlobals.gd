extends Node

const TILE_SIZE := 16.0
const HALF_TILE_SIZE := TILE_SIZE / 2.0


var _center_node: Node2D;

func _ready():
	_center_node = Node2D.new()
	add_child(_center_node)


func setup():
	pass


func get_global_mouse_position() -> Vector2:
	return _center_node.get_global_mouse_position()
