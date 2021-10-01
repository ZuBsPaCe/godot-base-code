class_name Cooldown
extends Reference


var done := false
var secs: float

var time_left:float setget ,_get_time_left


var _timer: Timer

enum TimerAutoStart {
	AUTO_START,
	STOPPED
}


func setup(p_parent_node: Node, p_secs: float, p_done: bool, auto_start = TimerAutoStart.AUTO_START):
	done = p_done

	secs = p_secs

	_timer = Timer.new()
	_timer.wait_time = p_secs
	_timer.one_shot = true

	if !done && auto_start == TimerAutoStart.AUTO_START:
		_timer.autostart = true

	# warning-ignore:return_value_discarded
	_timer.connect("timeout", self, "_timeout")

	p_parent_node.add_child(_timer)

func restart():
	done = false
	_timer.start(secs)

func stop():
	_timer.stop()

func _timeout():
	done = true

func _get_time_left() -> float:
	return _timer.time_left
