extends Node

var _camera: Camera2D


func setup(
		p_camera: Camera2D):
	_camera = p_camera


func shake(
		dir: Vector2, 
		intensity = 10.0, 
		frequency = 20.0, 
		duration = 0.5) -> void:
	_camera.start_shake(dir, intensity, frequency, duration)
