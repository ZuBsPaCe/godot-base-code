class_name MapCoords
extends RefCounted

var _coords := {}

var coords:
	get:
		return _coords.keys()

func _init(p_coords: Array):
	for coord in p_coords:
		_coords[coord] = true
		
func has_coord(coord: Vector2i) -> bool:
	return _coords.has(coord)

func size() -> int:
	return _coords.size()
