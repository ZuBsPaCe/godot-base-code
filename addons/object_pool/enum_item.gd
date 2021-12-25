tool
extends Reference

var name : String
var path : String

var enum_values := []

func _init(p_path: String, p_name: String, p_enum_values = []):
	path = p_path
	name = p_name
	enum_values = p_enum_values
