class_name StateMachine
extends Node


var current: int = -1

var _check_valid_states := false
var _valid_states := PackedInt32Array()
var _requested_states := PackedInt32Array()

var _blocked := false
var _enter_called := false

var _wait_secs: float = 0.0

var _leave_callback: Callable
var _enter_callback: Callable
var _process_callback: Callable


func setup(
		p_initial_state: int,
		
		p_enter_callback: Callable,
		p_process_callback: Callable,
		p_leave_callback: Callable) -> void:
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	current = -1
	_wait_secs = 0.0
	
	_enter_callback = p_enter_callback
	_process_callback = p_process_callback
	_leave_callback = p_leave_callback
	
	set_state(p_initial_state)


func set_state(p_next_state: int) -> void:
	_requested_states.append(p_next_state)


func set_state_immediate(p_next_state: int) -> void:
	_requested_states.resize(0)
	_requested_states.append(p_next_state)
	_wait_secs = 0.0
	_check_valid_states = false


func add_valid_state(p_valid_state: int):
	if !_check_valid_states:
		_valid_states.resize(0)
	_check_valid_states = true
	_valid_states.append(p_valid_state)


func wait(p_secs: float) -> void:
	_wait_secs = p_secs


func _perform_leave():
	assert(_enter_called)
	
	if _leave_callback.is_valid() && current >= 0:
		await _leave_callback.call()
	
	_enter_called = false
	_check_valid_states = false


func _perform_enter():
	assert(_requested_states.size() > 0)
	assert(!_enter_called)
	
	var next := _requested_states[0]
	_requested_states.remove_at(0)
	
	current = next
	
	if _enter_callback.is_valid():
		await _enter_callback.call()
	
	_enter_called = true


func _perform_process():
	assert(_enter_called)
	
	if _process_callback.is_valid():
		await _process_callback.call()


func _process(_delta):
	if _blocked:
		return
	
	if _perform_wait():
		return
	
	if !_enter_called:
		_blocked = true
		await _perform_enter()
		_blocked = false
	
	if _wait_requested():
		return
	
	if _requested_states.size() == 0:
		_blocked = true
		await _perform_process()
		_blocked = false
	else:
		while _requested_states.size() > 0:
			var next := _requested_states[0]
			
			if current == next:
				_requested_states.remove_at(0)
				continue
			
			if _check_valid_states && !_valid_states.has(next):
				printerr("StateMachine: Current state %d. Next State %d invalid." % [current, next])
				_requested_states.remove_at(0)
				continue
			
			_blocked = true
			await _perform_leave()
			_blocked = false
			
			if _wait_requested():
				return
			
			_blocked = true
			await _perform_enter()
			_blocked = false
			
			if _wait_requested():
				return
			
			_blocked = true
			await _perform_process()
			_blocked = false
			
			if _wait_requested():
				return


func _wait_requested() -> bool:
	return _wait_secs > 0.0


func _perform_wait() -> bool:
	if _wait_secs > 0.0:
		_wait_secs -= get_process_delta_time()
		if _wait_secs > 0.0:
			return true
			
		_wait_secs = 0.0
	
	return false
