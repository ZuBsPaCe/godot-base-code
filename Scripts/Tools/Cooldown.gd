class_name Cooldown
extends Reference


var done := false
var secs: float

var time_left : float setget ,_get_time_left


func _get_time_left():
	return _timer.time_left
	

var _timer: Timer

enum {
	AUTO_START,
	STOPPED
}


func setup(p_parent_node: Node, p_secs: float, p_done: bool, auto_start = AUTO_START):
	done = p_done
	
	secs = p_secs
	
	_timer = Timer.new()
	_timer.wait_time = p_secs
	_timer.one_shot = true
	
	if !done && auto_start == AUTO_START:
		_timer.autostart = true
	
	_timer.connect("timeout", self, "_timeout")
	
	p_parent_node.add_child(_timer)


func restart():
	done = false
	_timer.start(secs)


func restart_with(p_secs: float):
	secs = p_secs
	done = false
	_timer.start(secs)


func reset():
	done = false
	_timer.stop()


func stop():
	if _timer == null:
		return
	_timer.stop()


func set_done():
	stop()
	done = true


func _timeout():
	done = true
