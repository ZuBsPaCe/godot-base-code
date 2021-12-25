@tool
extends Node

const EnumItem := preload("res://addons/object_pool/enum_item.gd")
const EnumValue := preload("res://addons/object_pool/enum_value.gd")


func _init():
	pass


func save_config(path: String, enum_items: Array):
	print("Pool: Saving [%s]" % path)
	
	var file = File.new()
	file.open(path, File.WRITE)
	
	var serialized_enum_items := []
	for enum_item in enum_items:
		var serialized_enum_values := []
		for enum_value in enum_item.enum_values:
			var rpath = null
			if enum_value.scene != null:
				rpath = enum_value.scene.resource_path
			serialized_enum_values.append(
				{
					"name": enum_value.name,
					"value": enum_value.value,
					"resource_path": rpath
				})
				
		serialized_enum_items.append(
			{
				"path": enum_item.path,
				"name": enum_item.name,
				"enum_values": serialized_enum_values
			})
	
	var config := {}
	
	config["enum_items"] = serialized_enum_items
	
	file.store_line(JSON.print(config, "\t"))

	file.close()


func load_config(path: String) -> Array:
	var file = File.new()
	
	var enum_items := []
	
	if file.file_exists(path):
		print("Pool: Loading [%s]" % path)
		
		file.open(path, File.READ)
		
		var json = JSON.new()
		var ret = json.parse(file.get_as_text())
		
		if ret == OK:
			var config : Dictionary = json.get_data()
		
			var serialized_enum_items : Array = config["enum_items"]
			for item in serialized_enum_items:
				
				var enum_values := []
				
				var serialized_enum_values : Array = item["enum_values"]
				for value_item in serialized_enum_values:
					var enum_value := EnumValue.new(value_item["name"], value_item["value"])
					var rpath = value_item["resource_path"]
					if rpath != null:
						enum_value.scene = load(value_item["resource_path"])
						assert(enum_value.scene is PackedScene)
					
					enum_values.append(enum_value)
				
				enum_items.append(EnumItem.new(item["path"], item["name"], enum_values))
		else:
			print("Pool: Failed to parse file [%s]." % path)
		file.close()
	else:
		print("Pool: Config file [%s] does not exist yet." % path)

	return enum_items
