class_name StateMachine
extends Node

# Why a state machine?
#
# This line has a huge problem:
# await get_tree().create_timer(1.0).timeout
#
# Currently it is not possible to stop the async method
# from continuing. This is a problem for instances managed
# by our object_pool addon. The instance can be destroyed and
# reused immediately, but we don't want the code to continue
# after the await.
#
# This problem can be solved by using StateMachine.wait() instead
# and used StateMachine.setup() after creating a pooled object.


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
	if _wait_secs > 0.0:
		_wait_secs -= delta
		if _wait_secs > 0.0:
			return
		_wait_secs = 0.0
	
	if current_state != next_state:
		if current_state >= 0:
			emit_signal("leave_state", current_state)
		current_state = next_state
		emit_signal("enter_state", current_state)
	
	emit_signal("process_state", current_state)
