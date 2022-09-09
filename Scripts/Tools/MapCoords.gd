class_name MapCoords
extends RefCounted

var _coords := {}
var _temp_coord := Vector2i.ZERO

var coords:
	get:
		return _coords.keys()

func _init(p_coords: Array):
	for coord in p_coords:
		_coords[coord] = true
		
func has_coord(coord: Vector2i) -> bool:
	return _coords.has(coord)

func has_coord_at_dir(coord: Vector2i, dir: int) -> bool:
	_temp_coord.x = coord.x
	_temp_coord.y = coord.y
	return _coords.has(Tools.step_dir(_temp_coord, dir))

func size() -> int:
	return _coords.size()
