class_name Map
extends Reference

var width : int setget ,_get_width
var height : int setget ,_get_width
var size : int setget ,_get_size


var _map := []
var _marked_indexes := []

func _init(p_width : int, p_height : int) -> void:
	width = p_width
	height = p_height
	size = width * height
	_map.resize(size)

func is_valid(x : int, y : int) -> bool:
	return x >= 0 && y >= 0 && x < width && y < height

func set_item(x : int, y : int, item) -> void:
	_map[y * width + x] = item

func get_item(x : int, y : int):
	return _map[y * width + x]

func get_item_if_valid(x : int, y : int):
	if !is_valid(x, y):
		return null
	return get_item(x, y)

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

func _get_width() -> int:
	return width

func _get_height() -> int:
	return height

func _get_size() -> int:
	return size
