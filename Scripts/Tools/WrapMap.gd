class_name WrapMap
extends Map


func set_all(item) -> void:
	_map.fill(item)
	
		
func is_valid(_coord: Vector2i) -> bool:
	return true


func get_index(coord: Vector2i) -> int:
	return posmod(coord.y, height) * width + posmod(coord.x, width)
