extends Node2D


const Direction4 := preload("res://Scripts/Tools/Direction4.gd").Direction4

var _raycast : RayCast2D


func _ready():
	_raycast = RayCast2D.new()
	_raycast.enabled = false
	add_child(_raycast)


# Map Helpers

func to_coord(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(pos.x / Globals.TILE_SIZE),
		int(pos.y / Globals.TILE_SIZE))


func to_pos(coord: Vector2i) -> Vector2:
	return Vector2(
		coord.x * Globals.TILE_SIZE,
		coord.y * Globals.TILE_SIZE)

func to_random_pos(coord: Vector2i) -> Vector2:
	return Vector2(
		coord.x * Globals.TILE_SIZE + randf() * Globals.TILE_SIZE,
		coord.y * Globals.TILE_SIZE + randf() * Globals.TILE_SIZE)

func to_center_pos(coord: Vector2i) -> Vector2:
	return Vector2(
		coord.x * Globals.TILE_SIZE + Globals.HALF_TILE_SIZE,
		coord.y * Globals.TILE_SIZE + Globals.HALF_TILE_SIZE)


func manhattan_distance(from: Vector2i, to: Vector2i) -> float:
	return abs(to.x - from.x) + abs(to.y - from.y)


# Array of Arrays: Radius => List of coord offsets
var _coord_offsets_in_circle := [[Vector2i()]]
var _distances_in_circle := [[0.0]]

var map_coords_in_circle: Array[Vector2i] = []
var map_distances_in_circle: Array[float] = []

func get_map_coords_in_circle(map: Map, coord: Vector2i, tile_radius: int) -> void:
	if _coord_offsets_in_circle.size() < tile_radius:
		for r in range(_coord_offsets_in_circle.size(), tile_radius + 1):
			var coord_offsets : Array = _coord_offsets_in_circle[r - 1].duplicate()
			var distances : Array = _distances_in_circle[r - 1].duplicate()
			for offset_y in range(-r, r + 1):
				for offset_x in range(-r, r + 1):				
					var distance := sqrt(offset_x * offset_x + offset_y * offset_y)
					
					if distance > r or distance <= r - 1:
						continue
						
					coord_offsets.append(Vector2i(offset_x, offset_y))
					distances.append(distance)
			
			_coord_offsets_in_circle.append(coord_offsets)
			_distances_in_circle.append(distances)

	# TODO: Check if map_distances_in_circle is needed...
	map_coords_in_circle.clear()
	map_distances_in_circle.clear()
	
	var current_coord_offsets : Array = _coord_offsets_in_circle[tile_radius]
	var current_distances : Array = _distances_in_circle[tile_radius]
	
	for i in current_coord_offsets.size():
		var coord_offset : Vector2i = current_coord_offsets[i]
		var final := coord + coord_offset
		if map.is_valid(final):
			map_coords_in_circle.append(final)
			map_distances_in_circle.append(current_distances[i])


func step_dir(coord:Vector2i, dir) -> Vector2i:
	match dir:
		Direction4.N:
			return Vector2i(coord.x, coord.y - 1)
		Direction4.E:
			return Vector2i(coord.x + 1, coord.y)
		Direction4.S:
			return Vector2i(coord.x, coord.y + 1)
		Direction4.W:
			return Vector2i(coord.x - 1, coord.y)
		_:
			@warning_ignore(assert_always_false)
			assert(false)
	return coord
			
func step_diagonal(coord:Vector2i, dir1, dir2) -> Vector2i:
	if dir1 == Direction4.N && dir2 == Direction4.E || dir1 == Direction4.E && dir2 == Direction4.N:
		return Vector2i(coord.x + 1, coord.y - 1)
	elif dir1 == Direction4.E && dir2 == Direction4.S || dir1 == Direction4.S && dir2 == Direction4.E:
		return Vector2i(coord.x + 1, coord.y + 1)
	elif dir1 == Direction4.S && dir2 == Direction4.W || dir1 == Direction4.W && dir2 == Direction4.S:
		return Vector2i(coord.x - 1, coord.y + 1)
	else:
		return Vector2i(coord.x - 1, coord.y - 1)
	

func is_reverse(dir1, dir2) -> bool:
	return (
		dir1 == Direction4.N && dir2 == Direction4.S ||
		dir1 == Direction4.S && dir2 == Direction4.N ||
		dir1 == Direction4.E && dir2 == Direction4.W ||
		dir1 == Direction4.W && dir2 == Direction4.E)
		
func turn_left(dir) -> int:
	if dir >= 1:
		return dir - 1
	return 3
	
func turn_right(dir) -> int:
	if dir < 3:
		return dir + 1
	return 0

func turn(dir, diff) -> int:
	return posmod(dir + diff, 4)
	
func reverse(dir) -> int:
	return (dir + 2) % 4
	
		
func get_vec_from_dir(dir) -> Vector2:
	match dir:
		Direction4.N:
			return Vector2.UP
		Direction4.E:
			return Vector2.RIGHT
		Direction4.S:
			return Vector2.DOWN
		Direction4.W:
			return Vector2.LEFT
		_:
			@warning_ignore(assert_always_false)
			assert(false)
	return Vector2.ZERO

func get_map_islands(map: Map) -> Array[MapIsland]:
	return get_map_islands_in_section(map, Rect2i(0, 0, map.width, map.height))

func get_map_islands_in_section(map: Map, section: Rect2i) -> Array[MapIsland]:
	var seen_map := {}
	var coord := Vector2i.ZERO
	
	var map_islands := []
	
	for y in range(section.position.y, section.end.y):
		for x in range(section.position.x, section.end.x):
			coord.x = x
			coord.y = y
			
			if coord in seen_map:
				continue
			
			var item = map.get_item(coord)
			var map_island := _get_map_island(map, seen_map, coord, section, item)
			#print(str(map_island))
			map_islands.append(map_island)
	
	return map_islands

func _get_map_island(map: Map, seen_map: Dictionary, start_coord: Vector2i, section: Rect2i, item: int) -> MapIsland:
	var heads := [start_coord]

	var island := [start_coord]	
	seen_map[start_coord] = true

	var checks := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

	while !heads.is_empty():
		var coord: Vector2i = heads.pop_front()

		for check in checks:
			var check_coord := coord + check

			if check_coord in seen_map:
				continue
			
			if !section.has_point(check_coord):
				continue
				
			if map.is_item(check_coord, item):
				
				# Prevent islands from having holes, otherwise creating outlines
				# for occluders or such would get a lot more complicated!
				var could_loop := false
				for loop_check in checks:
					if loop_check != check_coord and section.has_point(loop_check) and map.is_item(loop_check, item) and island.has(loop_check):
						could_loop = true
						break
				
				if !could_loop:
					island.append(check_coord)
					seen_map[check_coord] = true
					heads.append(check_coord)

	return MapIsland.new(item, MapCoords.new(island), start_coord)


# Color Helpers

func get_alpha_1(color: Color) -> Color:
	return Color(color.r, color.g, color.b, 1.0)

func get_alpha_0(color: Color) -> Color:
	return Color(color.r, color.g, color.b, 0.0)

# Array Helpers

func rand_item(array : Array) -> Variant:
	return array[randi() % array.size()]

func rand_pop(array : Array) -> Variant:
	var index := randi() % array.size()
	var object = array[index]
	array.remove_at(index)
	return object

func rand_color(alpha = 1.0):
	return Color(randf(), randf(), randf(), alpha)


# Raycast Helpers

var raycast_object:Object
var raycast_collision_point:Vector2

func raycast_dir(from:Vector2, dir: Vector2, collision_mask:int, view_distance: float) -> bool:
	assert(dir.is_equal_approx(dir.normalized()), "Vector is not normalized!")

#	raycast.clear_exceptions()
#	raycast.add_exception(from)

	_raycast.position = from
	_raycast.target_position = from + dir * view_distance
	_raycast.collision_mask = collision_mask

	_raycast.force_raycast_update()
	
	raycast_object = _raycast.get_collider()
	if raycast_object != null:
		raycast_collision_point = _raycast.get_collision_point()
		return true
	
	raycast_collision_point = _raycast.cast_to
	return false


func raycast_to(pos:Vector2, target_pos:Vector2, to: PhysicsBody2D, collision_mask:int, view_distance: float) -> bool:
	
	if to == null:
		return false
#	raycast.clear_exceptions()
#	raycast.add_exception(from)

	#_raycast.position = from.position
	_raycast.position = pos
	
	_raycast.target_position = (target_pos - pos).limit_length(view_distance)
	_raycast.collision_mask = collision_mask

	_raycast.force_raycast_update()
	
#	debug.append(_raycast.position)
#	debug.append(_raycast.cast_to)
#	z_index = 100
#	update()

	return _raycast.get_collider() == to

#var debug := []
#
#func _draw():
#	for i in range(0, debug.size(), 2):
#		draw_line(debug[i], debug[i] + debug[i + 1], Color.red, 2)
#
#	debug.clear()


func save_data(file_name: String, data: Dictionary) -> void:
	var path := "user://" + file_name
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file = null
	
	
func load_data(file_name: String, data: Dictionary) -> void:
	var path := "user://" + file_name
	if not FileAccess.file_exists(path):
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var save_data: Dictionary = JSON.parse_string(file.get_as_text())
	
	data.merge(save_data, true)

	file = null


func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN || mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
