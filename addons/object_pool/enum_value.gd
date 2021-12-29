@tool
extends RefCounted

signal enum_value_changed()

var name : String
var value : int
var scene_path : String

func _init(p_name, p_value, p_scene_path):
	name = p_name
	value = p_value
	scene_path = p_scene_path
