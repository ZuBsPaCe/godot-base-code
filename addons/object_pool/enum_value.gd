@tool
extends RefCounted

signal enum_value_changed()

var name : String
var value : int
@export var scene : PackedScene:
	get:
		return scene
	set(value):
		scene = value
		emit_signal("enum_value_changed")


func _init(p_name, p_value):
	name = p_name
	value = p_value
