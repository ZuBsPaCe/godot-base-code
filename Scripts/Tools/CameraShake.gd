extends Camera2D

#warning-ignore-all:RETURN_VALUE_DISCARDED

var _bounce_tween: SceneTreeTween

var _intensity_tween: SceneTreeTween
var _intensity: float

var _bounce_time: float
var _direction: Vector2


func _on_bounce_finished():
	_bounce(false)


func start_shake(direction: Vector2, intensity: float, frequency: float, duration: float):
	if _intensity > intensity:
		return

	_direction = -direction

	if _intensity_tween:
		_intensity_tween.kill()
	if _bounce_tween:
		_bounce_tween.kill()
	
	_intensity_tween = create_tween()
	_bounce_tween = create_tween()
	_bounce_tween.connect("finished", self, "_on_bounce_finished")
		
	_intensity = intensity
	_intensity_tween.tween_property(self, "_intensity", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_bounce_time = 1.0 / frequency
	_bounce(true)


func _bounce(first: bool):
	if _intensity == 0.0 && offset == Vector2.ZERO:
		#print_debug("Bounce DONE")
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
		#print_debug("First duration: %s" % first_duration)

		_bounce_tween.tween_property(self, "offset", new_offset, first_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_bounce_tween = create_tween()
		_bounce_tween.connect("finished", self, "_on_bounce_finished")
		_bounce_tween.tween_property(self, "offset", new_offset, _bounce_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

