@tool
extends Button

@onready var _color_rect := $ColorRect

var _init_initialized
var _init_color


var color : Color:
	get:
		return _color_rect.color
	set(value):
		_color_rect.color = value
		_color_rect.visible = true


var initialized : bool:
	get:
		return _color_rect.visible
	set(value):
		_color_rect.visible = value


func setup(init_initialized, init_color):
	_init_initialized = init_initialized
	_init_color = init_color


func _ready():
	_color_rect.color = _init_color
	initialized = _init_initialized
