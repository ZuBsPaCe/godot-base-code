@tool
extends Button

onready var _color_rect := $ColorRect

var _init_initialized
var _init_color

var color:Color setget _set_color, _get_color
var initialized:bool setget _set_initialized, _get_initialized


func setup(init_initialized, init_color):
	_init_initialized = init_initialized
	_init_color = init_color


func _ready():
	_color_rect.color = _init_color
	_set_initialized(_init_initialized)

func _set_color(value):
	_color_rect.color = value
	_color_rect.visible = true


func _get_color():
	return _color_rect.color


func _set_initialized(value):
	_color_rect.visible = value


func _get_initialized():
	return _color_rect.visible
