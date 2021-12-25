tool
extends Reference

var name : String
var value : int
export(PackedScene) var scene : PackedScene setget _set_scene,_get_scene

signal enum_value_changed()

func _init(p_name, p_value):
	name = p_name
	value = p_value

func _set_scene(value):
	scene = value
	emit_signal("enum_value_changed")
	
func _get_scene():
	return scene
