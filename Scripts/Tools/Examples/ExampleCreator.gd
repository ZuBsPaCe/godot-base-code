extends Node

var _enity_container
var _player_scene: PackedScene # = preload(..)


var _player


func setup(
		p_entity_container):
	_enity_container = p_entity_container


func create_player(pos: Vector2) -> void:
	assert(_player == null)
	_player = _player_scene.instantiate()
	_player.setup(pos)
	_enity_container.add_child(_player)


func destroy_player() -> void:
	_enity_container.remove_child(_player)
	_player = null
