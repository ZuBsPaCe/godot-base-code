extends Node

const TILE_SIZE := 16.0
const HALF_TILE_SIZE := TILE_SIZE / 2.0

var _enity_container
var _player_scene: PackedScene

var camera: Camera2D
var player: RigidDynamicBody2D

var _center_node: Node2D;

func _ready():
	_center_node = Node2D.new()
	add_child(_center_node)

func setup(
	p_camera: Camera2D,
	p_entity_container,
	p_player_scene: PackedScene):

	camera = p_camera
	_enity_container = p_entity_container
	_player_scene = p_player_scene

func create_player(pos: Vector2) -> void:
	assert(player == null)
	player = _player_scene.instantiate()
	player.setup(pos)
	_enity_container.add_child(player)

func destroy_player() -> void:
	_enity_container.remove_child(player)
	player = null


func shake(dir: Vector2) -> void:
	camera.start_shake(dir, 0.5, 20, 0.15)

func get_global_mouse_position() -> Vector2:
	return _center_node.get_global_mouse_position()
	
