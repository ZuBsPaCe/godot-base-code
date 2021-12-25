extends Node

# Usage:
# - Enable the "Object Pool" Plugin
# - Create a new enum, for example "Foo" with some values
# - You can import the enum like this:
#   const Foo := preload("res://foo.gd").Foo
# - Add the enum name "Foo" in the Pool Plugin Tab and
#   assign scenes to each value there.
# - Add a autoload instance called "PoolFoo" from pool.gd.
# - Use the pool like this:
#   var instance = PoolTest.create(Test.Fudi)
#   PoolTest.destroy(Test.Fudi, instance)


const Helper := preload("res://addons/object_pool/helper.gd")

const config_path = "res://pool.json"

var enum_name : String

var _helper
var _pools := []
var _scenes := []


func _ready():
	enum_name = str(name).replace("Pool", "").capitalize().replace(" ", "")
	
	_helper = Helper.new()
	
	var enum_items = _helper.load_config(config_path)
	
	for enum_item in enum_items:
		if enum_item.name == enum_name:
			for enum_value in enum_item.enum_values:
				_pools.append([])
				_scenes.append(enum_value.scene)
	
	if _pools.size() > 0:
		print("Autoloaded %s Pool with %d different types." % [enum_name, _pools.size()])
	else:
		print("Autoloaded %s Pool failed." % enum_name)


func create(enum_value) -> Node2D:
	var pool: Array = _pools[enum_value]
	var instance: Node2D
	if pool.size() > 0:
		instance = pool.pop_back()
	else:
		instance = _scenes[enum_value].instance()
	get_tree().root.add_child(instance)
	return instance

func destroy(enum_value, instance: Node2D):
	instance.get_parent().remove_child(instance)
	_pools[enum_value].append(instance)
	
