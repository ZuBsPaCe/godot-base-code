class_name StateMachine
extends Node


var current_state: int = -1
var next_state: int = -1

var _wait_secs: float = 0.0

signal leave_state(p_state: int)
signal process_state(p_state: int)
signal enter_state(p_state: int)

func setup(p_initial_state: int = -1) -> void:
	current_state = -1
	next_state = p_initial_state
	_wait_secs = 0.0

func set_state(p_next_state: int) -> void:
	next_state = p_next_state
	_wait_secs = 0.0

func wait(p_secs: float) -> void:
	_wait_secs = p_secs

func _process(delta):
	if current_state != next_state:
		if current_state >= 0:
			emit_signal("leave_state", current_state)
		current_state = next_state
		emit_signal("enter_state", current_state)
	
	if _wait_secs > 0.0:
		_wait_secs -= delta
		if _wait_secs > 0.0:
			return
		_wait_secs = 0.0
	
	emit_signal("process_state", current_state)
