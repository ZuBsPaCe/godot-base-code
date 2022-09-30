extends Node

const TILE_SIZE := 16.0
const HALF_TILE_SIZE := TILE_SIZE / 2.0

const SETTING_FULLSCREEN := "Fullscreen"
const SETTING_WINDOW_WIDTH := "Window Width"
const SETTING_WINDOW_HEIGHT := "Window Height"
const SETTING_MUSIC_VOLUME := "Music"
const SETTING_SOUND_VOLUME := "Sound"


var _center_node: Node2D
var _settings: Dictionary


func _ready():
	_center_node = Node2D.new()
	add_child(_center_node)


func setup():
	var screen_size := DisplayServer.screen_get_size()
	_settings = {
		Globals.SETTING_FULLSCREEN: true,
		Globals.SETTING_WINDOW_WIDTH: screen_size.x / 2,
		Globals.SETTING_WINDOW_HEIGHT: screen_size.y / 2,
		Globals.SETTING_MUSIC_VOLUME: 0.8,
		Globals.SETTING_SOUND_VOLUME: 0.8
	}
	
	Tools.load_data("settings.json", _settings)


func get_setting(name: String):
	return _settings[name]


func set_setting(name: String, value):
	_settings[name] = value


func save_settings():
	Tools.save_data("settings.json", _settings)


func get_global_mouse_position() -> Vector2:
	return _center_node.get_global_mouse_position()
