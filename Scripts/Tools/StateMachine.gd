class_name StateMachine
extends Node


var current: int = -1
var runner := Runner.new()

var _check_valid_states := false
var _valid_states := {}
var _requested_states := PoolIntArray()

var _blocked := false
var _enter_called := false

var _wait_secs := 0.0
var _wait_a_frame := false

var _initial_state: int
var _leave_callback: FuncRef
var _enter_callback: FuncRef
var _process_callback: FuncRef


# The caller can set unused callbacks to "FuncRef.new()"
func setup(
		p_initial_state: int,
		
		p_enter_callback: FuncRef,
		p_process_callback: FuncRef,
		p_leave_callback: FuncRef) -> void:
	
	#pause_mode = PAUSE_MODE_PROCESS
	
	current = -1
	_wait_secs = 0.0
	
	_enter_callback = p_enter_callback
	_process_callback = p_process_callback
	_leave_callback = p_leave_callback
	
	set_state(p_initial_state)


func set_state(p_next_state: int) -> void:
	_requested_states.append(p_next_state)


func set_state_after_frame(p_next_state: int) -> void:
	set_state(p_next_state)
	_wait_a_frame = true


# - Current state will not call leave callback
# - Callbacks of current state can still be yielding. Check runner.aborted 
#   by creating a local copy of it to abort properly.
# - If called inside enter callback, process callback of current state won't run.
func set_state_immediate(p_next_state: int) -> void:
	_requested_states.resize(0)
	_requested_states.append(p_next_state)
	_wait_secs = 0.0
	_check_valid_states = false
	
	runner.aborted = true
	runner = Runner.new()
	
	_blocked = false


func add_valid_state(p_valid_state: int):
	if !_check_valid_states:
		_valid_states.clear()
	_check_valid_states = true
	_valid_states[p_valid_state] = true


func wait(p_secs: float) -> void:
	_wait_secs = p_secs


func _before_enter():
	assert(_requested_states.size() > 0)
	assert(!_enter_called)
	
	var next := _requested_states[0]
	_requested_states.remove(0)
	
	current = next


func _after_leave():
	_enter_called = false
	_check_valid_states = false


func _process(delta):
	if _blocked:
		return
	
	if _perform_wait(delta):
		return
		
	var current_runner = runner
	
	if !_enter_called:
		# Enter Begin
		_before_enter()
		
		if _enter_callback.is_valid():
			_blocked = true
			var result = _enter_callback.call_func()
			if result is GDScriptFunctionState and result.is_valid():
				yield(result, "completed")
			if current_runner.aborted:
				return
			_blocked = false
		
		_enter_called = true
		# Enter End
	
	if _wait_requested():
		return
	
	if _requested_states.size() == 0:
		
		# Process Begin
		assert(_enter_called)
		if _process_callback.is_valid():
			_blocked = true
			var result = _process_callback.call_func()
			if result is GDScriptFunctionState and result.is_valid():
				yield(result, "completed")
			if current_runner.aborted:
				return
			_blocked = false
		# Process End
		
	else:
		while _requested_states.size() > 0:
			var next := _requested_states[0]
			
			if current == next:
				_requested_states.remove(0)
				continue
			
			if _check_valid_states && !_valid_states.has(next):
				printerr("StateMachine: Current state %d. Next State %d invalid." % [current, next])
				_requested_states.remove(0)
				continue
			
			# Leave Begin
			assert(_enter_called)

			if _leave_callback.is_valid() and current >= 0:
				_blocked = true
				var result = _leave_callback.call_func()
				if result is GDScriptFunctionState and result.is_valid():
					yield(result, "completed")
				if current_runner.aborted:
					return
				_blocked = false
			
			_after_leave()
			# Leave End
			
			if _wait_requested():
				return
			
			# Enter Begin
			_before_enter()
			
			if _enter_callback.is_valid():
				_blocked = true
				var result = _enter_callback.call_func()
				if result is GDScriptFunctionState and result.is_valid():
					yield(result, "completed")
				if current_runner.aborted:
					return
				_blocked = false
			_enter_called = true
			# Enter End
			
			
			if _wait_requested():
				return
			
			# Process Begin
			assert(_enter_called)
			if _process_callback.is_valid():
				_blocked = true
				var result = _process_callback.call_func()
				if result is GDScriptFunctionState and result.is_valid():
					yield(result, "completed")
				if current_runner.aborted:
					return
				_blocked = false
			# Process End
			
			if _wait_requested():
				return


func _wait_requested() -> bool:
	if _wait_a_frame:
		_wait_a_frame = false
		return true
		
	return _wait_secs > 0.0


func _perform_wait(delta: float) -> bool:
	if _wait_secs > 0.0:
		_wait_secs -= delta
		if _wait_secs > 0.0:
			return true
			
		_wait_secs = 0.0
	
	return false
