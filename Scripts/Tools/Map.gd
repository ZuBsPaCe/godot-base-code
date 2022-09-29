class_name Map
extends RefCounted

var width : int
var height : int
var size : int

var _map := []
var _marked_indexes := []


func _init(p_width : int, p_height : int) -> void:
	width = p_width
	height = p_height
	size = width * height
	_map.resize(size)


func clone_from_map(map) -> void:
	width = map.width
	height = map.height
	size = width * height
	_map = Array(map._map)


func set_all(item) -> void:
	_map.fill(item)


# Same for Map and WrapMap
func is_inside(coord: Vector2i) -> bool:
	return coord.x >= 0 && coord.y >= 0 && coord.x < width && coord.y < height

func is_inside_xy(x: int, y: int) -> bool:
	return is_inside(Vector2i(x, y))


func is_offset_inside(coord: Vector2i, offset: Vector2i) -> bool:
	var final := coord + offset
	return is_inside(final)


# Will be overriden by WrapMap
func is_valid(coord: Vector2i) -> bool:
	return coord.x >= 0 && coord.y >= 0 && coord.x < width && coord.y < height


func is_valid_xy(x: int, y: int) -> bool:
	return is_valid(Vector2i(x, y))


func is_index_valid(index: int) -> bool:
	return index >= 0 && index < size


func get_index(coord: Vector2i) -> int:
	return coord.y * width + coord.x


func get_coord(index: int) -> Vector2i:
	@warning_ignore(integer_division)
	var y = int(floor(index / width))
	var x = index - y * width
	return Vector2i(x, y)


func posmod_coord(coord: Vector2i) -> Vector2i:
	return Vector2i(posmod(coord.x, width), posmod(coord.y, height))


# The coord must be valid
func set_item(coord: Vector2i, item) -> void:
	_map[get_index(coord)] = item

func set_item_xy(x: int, y: int, item) -> void:
	set_item(Vector2i(x, y), item)


func set_indexed_item(index: int, item) -> void:
	_map[index] = item

# The coord must be valid
func get_item(coord: Vector2i):
	return _map[get_index(coord)]


func get_item_xy(x: int, y: int):
	return get_item(Vector2i(x, y))


# Will check, if the coord is valid
func get_item_with_offset(coord: Vector2i, offset: Vector2i):
	var final := coord + offset
	if !is_valid(final):
		return null
	return get_item(final)


func get_indexed_item(index: int):
	return _map[index]


# The coord must be valid
func is_set(coord: Vector2i) -> bool:
	return get_item(coord) != null
	
	
func is_set_xy(x: int, y: int) -> bool:
	return is_set(Vector2i(x, y))


# The coord must be valid
func is_item(coord: Vector2i, value) -> bool:
	return get_item(coord) == value


func is_item_xy(x: int, y: int, value) -> bool:
	return is_item(Vector2i(x, y), value)


# Will check, if the coord is valid
func is_item_with_offset(coord: Vector2i, offset: Vector2i, value) -> bool:
	return get_item_with_offset(coord, offset) == value


# Will check, if the coord is valid
func is_item_at_dir4(coord: Vector2i, dir4, value) -> bool:
	match dir4:
		0:
			return get_item_with_offset(coord, Vector2i(0, -1)) == value
		1:
			return get_item_with_offset(coord, Vector2i(1, 0)) == value
		2:
			return get_item_with_offset(coord, Vector2i(0, 1)) == value
		3:
			return get_item_with_offset(coord, Vector2i(-1, 0)) == value
		_:
			@warning_ignore(assert_always_false)
			assert(false)
	return false



func get_neighbour_count(coord: Vector2i, value) -> int:
	var count := 0
	
	if is_item_with_offset(coord, Vector2i(-1, -1), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(0, -1), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(1, -1), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(1, 0), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(1, 1), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(0, 1), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(-1, 1), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(-1, 0), value):
		count += 1

	return count


func get_direct_neighbour_count(coord: Vector2i, value) -> int:
	var count := 0
	
	if is_item_with_offset(coord, Vector2i(0, -1), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(1, 0), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(0, 1), value):
		count += 1
	if is_item_with_offset(coord, Vector2i(-1, 0), value):
		count += 1

	return count


func clear_marks() -> void:
	_marked_indexes.clear()


func mark_item(x: int, y: int) -> void:
	_marked_indexes.append(y * width + x)


func set_marked_items(item) -> void:
	for index in _marked_indexes:
		_map[index] = item
