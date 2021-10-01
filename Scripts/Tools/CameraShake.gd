extends Camera2D

#warning-ignore-all:RETURN_VALUE_DISCARDED

var _bounce_tween := Tween.new()

var _intensity_tween := Tween.new()
var _intensity: float

var _bounce_time: float
var _direction: Vector2


func _ready():
	add_child(_intensity_tween)

	_bounce_tween.connect("tween_all_completed", self, "_on_bounce_completed")
	add_child(_bounce_tween)


func _on_bounce_completed():
	_bounce(false)

func start_shake(direction: Vector2, intensity: float, frequency: float, duration: float):
	if _intensity > intensity:
		return

	_direction = -direction

	if _intensity_tween.is_active() || _bounce_tween.is_active():
		# Workaround: Does not work well, if we call remove_all() and start() in the same frame for tweens, which are currently active...
		_intensity_tween.remove_all()	
		_bounce_tween.remove_all()
		yield(get_tree(), "idle_frame")

	_intensity = intensity
	_intensity_tween.interpolate_property(self, "_intensity", _intensity, 0.0, duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_intensity_tween.start()

	_bounce_time = 1.0 / frequency
	_bounce(true)


func _bounce(first: bool):
	if _intensity == 0.0 && offset == Vector2.ZERO:
		print_debug("Bounce DONE")
		return

	var new_offset := _direction * _intensity
	_direction *= -1

	_direction = _direction.rotated(randf() * deg2rad(5.0))

	if first:
		# Starting at center, not at extreme => bounce_time / 2.
		# Take into account, that there could already be an offset. Reduce / Increase bounce_time accordingly.

		var usual_distance := new_offset.length() + 0.00001
		var current_distance := new_offset.distance_to(offset)

		var first_duration := current_distance / usual_distance * _bounce_time / 2.0 
		print_debug("First duration: %s" % first_duration)

		_bounce_tween.interpolate_property(self, "offset", offset,  new_offset, first_duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
	else:
		_bounce_tween.interpolate_property(self, "offset", offset,  new_offset, _bounce_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

	_bounce_tween.start()

