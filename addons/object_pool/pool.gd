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

# These arrays contain an element for each enum value.
# Each element of _dead_pool is an array of instances, which are not alive.
# Each element of _alive_pool is an array of instances, which are alive.
# Each element of _packed_scenes is a loaded scene which will be instantiated.
var _dead_pools := []
var _alive_pools := []
var _packed_scenes := []

func _ready():
	enum_name = str(name).replace("Pool", "").capitalize().replace(" ", "")
	
	_helper = Helper.new()
	
	var enum_items = _helper.load_config(config_path)
	
	for enum_item in enum_items:
		if enum_item.name == enum_name:
			for enum_value in enum_item.enum_values:
				_dead_pools.append([])
				_alive_pools.append([])
				
				var scene = load(enum_value.scene_path)
				assert(scene is PackedScene)
						
				_packed_scenes.append(scene)
	
	if _dead_pools.size() > 0:
		print("Autoloaded %s Pool with %d different types." % [enum_name, _dead_pools.size()])
	else:
		print("Autoloaded %s Pool failed." % enum_name)


func create(enum_value, parent: Node2D) -> Node2D:
	var dead_pool: Array = _dead_pools[enum_value]
	
	var instance: Node2D
	if dead_pool.size() > 0:
		instance = dead_pool.pop_back()
	else:
		instance = _packed_scenes[enum_value].instantiate()
	
	instance.request_ready()
	
	parent.add_child(instance)
	
	_alive_pools[enum_value].append(instance)
	
	return instance

func destroy(enum_value, instance: Node2D):
	_alive_pools[enum_value].erase(instance)
	
	instance.get_parent().remove_child(instance)
	_dead_pools[enum_value].append(instance)
	

func destroy_all():
	for enum_value in _alive_pools.size():
		var alive_pool: Array = _alive_pools[enum_value]
		while !alive_pool.is_empty():
			destroy(enum_value, alive_pool[0])
