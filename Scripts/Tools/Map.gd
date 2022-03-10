class_name Map
extends RefCounted

var width : int
var height : int
var size : int


# TODO REMOVE THIS FROM HERE OMG
var _orbs := []

var _map := []
var _marked_indexes := []


func _init(p_width : int, p_height : int) -> void:
	width = p_width
	height = p_height
	size = width * height
	_map.resize(size)
	_orbs.resize(size)


func set_all(item) -> void:
	for index in size:
		_map[index] = item


func is_valid(x : int, y : int) -> bool:
	return x >= 0 && y >= 0 && x < width && y < height


func is_index_valid(index: int) -> bool:
	return index >= 0 && index < size


func get_index(x: int, y: int) -> int:
	return y * width + x


func get_coord(index: int) -> Array:
	var y = int(floor(index / width))
	var x = index - y * width
	return [x, y]


func set_item(x : int, y : int, item) -> void:
	_map[y * width + x] = item


func set_orb(x : int, y : int, orb:Node2D) -> void:
	_orbs[y * width + x] = orb
	
	
func try_get_orb(x : int, y : int) -> Node2D:
	var orb = _orbs[y * width + x]
	if orb != null:
		_orbs[y * width + x] = null
	return orb


func set_indexed_item(index: int, item) -> void:
	_map[index] = item


func get_item(x : int, y : int):
	return _map[y * width + x]


func get_item_if_valid(x : int, y : int):
	if !is_valid(x, y):
		return null
	return get_item(x, y)


func get_indexed_item(index: int):
	return _map[index]


func get_indexed_item_if_valid(index: int):
	if !is_index_valid(index):
		return null
	return _map[index]
	

func is_item(x: int, y: int, value) -> bool:
	if !is_valid(x, y):
		return false
	return get_item(x, y) == value
	

func is_item_or_invalid(x: int, y: int, value) -> bool:
	if !is_valid(x, y):
		return true
	return get_item(x, y) == value


func is_item_at_dir4(x: int, y: int, dir4, value) -> bool:
	match dir4:
		0:
			y -= 1
		1:
			x += 1
		2:
			y += 1
		3:
			x -= 1
		_:
			assert(false)
	return is_item(x, y, value)


func is_item_at_dir4_or_invalid(x: int, y: int, dir4, value) -> bool:
	match dir4:
		0:
			y -= 1
		1:
			x += 1
		2:
			y += 1
		3:
			x -= 1
		_:
			assert(false)
	return is_item_or_invalid(x, y, value)


func get_neighbour_count(x: int, y: int, value) -> int:
	var count := 0
	for check_y in range(y-1, y+2):
		for check_x in range(x-1, x+2):
			if check_x == x && check_y == y:
				continue
			if get_item_if_valid(check_x, check_y) == value:
				count += 1

	return count


func get_direct_neighbour_count(x: int, y: int, value) -> int:
	var count := 0

	if get_item_if_valid(x, y - 1) == value:
		count += 1

	if get_item_if_valid(x + 1, y) == value:
		count += 1

	if get_item_if_valid(x, y + 1) == value:
		count += 1

	if get_item_if_valid(x - 1, y) == value:
		count += 1

	return count


func clear_marks() -> void:
	_marked_indexes.clear()


func mark_item(x : int, y : int) -> void:
	_marked_indexes.append(y * width + x)


func set_marked_items(item) -> void:
	for index in _marked_indexes:
		_map[index] = item
