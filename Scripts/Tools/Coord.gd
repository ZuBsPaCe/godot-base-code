class_name Coord
extends Reference

const TILE_SIZE := 32.0
const HALF_TILE_SIZE := TILE_SIZE / 2.0

var x : int
var y : int

func _init(p_x = 0, p_y = 0) -> void:
	x = p_x
	y = p_y

func set_coord(other : Coord):
	x = other.x
	y = other.y

func set_vector(pos : Vector2) -> void:
	x = int(pos.x / TILE_SIZE)
	y = int(pos.y / TILE_SIZE)

func to_pos() -> Vector2:
	return Vector2(
		x * TILE_SIZE,
		y * TILE_SIZE)

func to_random_pos() -> Vector2:
	return Vector2(
		x * TILE_SIZE + randf() * TILE_SIZE,
		y * TILE_SIZE + randf() * TILE_SIZE)

func to_center_pos() -> Vector2:
	return Vector2(
		x * TILE_SIZE + HALF_TILE_SIZE,
		y * TILE_SIZE + HALF_TILE_SIZE)

func distance_to(other : Coord) -> float:
	var diff_x := other.x - x
	var diff_y := other.y - y
	return sqrt(diff_x * diff_x + diff_y * diff_y)

func distance_squared_to(other : Coord) -> float:
	var diff_x := other.x - x
	var diff_y := other.y - y
	return float(diff_x * diff_x + diff_y * diff_y)

func manhattan_distance_to(other : Coord) -> float:
	return abs(x - other.x) + abs(y - other.y)

func _to_string() -> String:
	return "%d/%d" % [x, y]
