class_name MultiStateMachine
extends Node


@export var pooled := false


class MultiState:
	var current_state: int
	var next_state: int
	
	var wait_secs: float
	
	func _init(p_initial_state: int):
		setup(p_initial_state)
	
	func setup(p_initial_state: int):
		current_state = -1
		next_state = p_initial_state
		wait_secs = 0.0
		
signal leave_state(p_instance: Node, p_state: int)
signal process_state(p_instance: Node, p_state: int)
signal enter_state(p_instance: Node, p_state: int)


var _instances := []

var _node_pool := []
var _return_to_pool := []


func setup():
	_perform_return_to_pool()
	_node_pool.append_array(_instances)
	_instances.clear()
	

func register(instance: Node, p_initial_state: int = -1) -> void:
	assert(!pooled)
	instance.set_meta("MultiState", MultiState.new(p_initial_state))
	_instances.append(instance)


func create(p_initial_state: int = -1) -> Node:
	assert(pooled)
	
	var instance: Node
	if _node_pool.size() > 0:
		instance = _node_pool.pop_back()
		var multi_state: MultiState = instance.get_meta("MultiState")
		multi_state.setup(p_initial_state)
	else:
		instance = Node.new()
		instance.set_meta("MultiState", MultiState.new(p_initial_state))
	
	_instances.append(instance)
	
	return instance


func destroy(instance: Node):
	if pooled:
		_return_to_pool.append(instance)


func set_state(instance: Node, p_next_state: int) -> void:
	var multi_state: MultiState = instance.get_meta("MultiState")
	instance.next_state = p_next_state
	instance.wait_secs = 0.0

func wait(instance: Node, p_secs: float) -> void:
	var multi_state: MultiState = instance.get_meta("MultiState")
	multi_state.wait_secs = p_secs

func _process(delta):
	_perform_return_to_pool()
	
	for instance in _instances:
		var multi_state: MultiState = instance.get_meta("MultiState")
		
		if multi_state.wait_secs > 0.0:
			multi_state.wait_secs -= delta
			if multi_state.wait_secs > 0.0:
				continue
			multi_state.wait_secs = 0.0
		
		if multi_state.current_state != multi_state.next_state:
			if multi_state.current_state >= 0:
				emit_signal("leave_state", instance, multi_state.current_state)
			multi_state.current_state = multi_state.next_state
			emit_signal("enter_state", instance, multi_state.current_state)
		
		emit_signal("process_state", instance, multi_state.current_state)

func _perform_return_to_pool():
	if !pooled || _return_to_pool.is_empty():
		return
	
	for destroyed_node in _return_to_pool:
		_instances.erase(destroyed_node)
		_node_pool.append(destroyed_node)
	
	_return_to_pool.clear()
