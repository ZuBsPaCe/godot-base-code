extends Node2D

const TILE_SIZE := 16.0
const HALF_TILE_SIZE := TILE_SIZE / 2.0


const Direction4 := preload("res://Scripts/Tools/Direction4.gd").Direction4

var _raycast : RayCast2D


func _ready():
	_raycast = RayCast2D.new()
	_raycast.enabled = false
	add_child(_raycast)


# Map Helpers

func to_coord(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(pos.x / TILE_SIZE),
		int(pos.y / TILE_SIZE))


func to_pos(coord: Vector2i) -> Vector2:
	return Vector2(
		coord.x * TILE_SIZE,
		coord.y * TILE_SIZE)

func to_random_pos(coord: Vector2i) -> Vector2:
	return Vector2(
		coord.x * TILE_SIZE + randf() * TILE_SIZE,
		coord.y * TILE_SIZE + randf() * TILE_SIZE)

func to_center_pos(coord: Vector2i) -> Vector2:
	return Vector2(
		coord.x * TILE_SIZE + HALF_TILE_SIZE,
		coord.y * TILE_SIZE + HALF_TILE_SIZE)


func manhattan_distance(from: Vector2i, to: Vector2i) -> float:
	return abs(to.x - from.x) + abs(to.y - from.y)


# Array of Arrays: Radius => List of coord offsets
var _coord_offsets_in_circle := [[Vector2i()]]
var _distances_in_circle := [[0.0]]

var map_coords_in_circle := []
var map_distances_in_circle := []

func get_map_coords_in_circle(map:Map, x:int, y:int, tile_radius:int) -> void:
	if _coord_offsets_in_circle.size() < tile_radius:
		for r in range(_coord_offsets_in_circle.size(), tile_radius + 1):
			var coord_offsets : Array = _coord_offsets_in_circle[r - 1].duplicate()
			var distances : Array = _distances_in_circle[r - 1].duplicate()
			for offset_y in range(-r, r + 1):
				for offset_x in range(-r, r + 1):
#					var real_x := x + offset_x
#					var real_y := y + offset_y
					
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
		var real_x : int = x + coord_offset.x
		var real_y : int = y + coord_offset.y
		if map.is_valid(real_x, real_y):
			map_coords_in_circle.append(Vector2i(real_x, real_y))
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
			return Vector2.ZERO

func get_map_islands(map: Map) -> Array:
	var seen_map := Map.new(map.width, map.height)
	seen_map.set_all(false)
	
	var map_islands := []
	
	for y in map.height:
		for x in map.width:
			if seen_map.get_item(x, y) == true:
				continue
			
			var item = map.get_item(x, y)
			var map_island := _get_map_island(map, seen_map, x, y, item)
			print(str(map_island))
			map_islands.append(map_island)
	
	return map_islands

func _get_map_island(map: Map, seen_map: Map, x: int, y: int, item: int) -> MapIsland:

	var start_coord := Vector2i(x, y)
	var heads := [start_coord]

	var island := [start_coord]	
	seen_map.set_item(start_coord.x, start_coord.y, true)

	var checks := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

	while !heads.is_empty():
		var coord: Vector2i = heads.pop_back()

		for check in checks:
			var check_coord := coord + check

			if seen_map.is_item(check_coord.x, check_coord.y, true):
				continue
				
			if map.is_item(check_coord.x, check_coord.y, item):
				island.append(check_coord)
				seen_map.set_item(check_coord.x, check_coord.y, true)
				heads.append(check_coord)

	return MapIsland.new(item, MapCoords.new(island))


func map_get_outline(map: Map, x: int, y: int, windedness: int, optimize = true) -> Array:
	assert(windedness == 1 or windedness == -1)
	
	# Important: We assume, that x/y starts at the topmost row, on its leftmost tile.
	
	var top_right := Vector2i(1, 0)
	var top_left := Vector2i(0, 0)
	var bottom_left := Vector2i(0, 1)
	var bottom_right := Vector2i(1, 1)
	
	var corners : Array
	
	var start := Vector2i(x, y)
	var coord := start
	
	var outline := []
	var start_dir = null
	
	var value: int = map.get_item(x, y)
	
	if windedness == 1:
		# Create clockwise outline
	
		if map.is_item_at_dir4(coord.x, coord.y, Direction4.E, value):
			start_dir = Direction4.E
			coord.x += 1
		elif map.is_item_at_dir4(coord.x, coord.y, Direction4.S, value):
			start_dir = Direction4.S
			coord.y += 1
		else:
			outline.append(coord + top_right)
			outline.append(coord + bottom_right)
			outline.append(coord + bottom_left)
			outline.append(coord + top_left)
			return outline
		
		# corner_index points to the bottom left corner if indexed with dir
		corners = [bottom_left, top_left, top_right, bottom_right]
		
	else:
		# Create counter-clockwise outline
		
		if map.is_item_at_dir4(coord.x, coord.y, Direction4.S, value):
			start_dir = Direction4.S
			coord.y += 1
		elif map.is_item_at_dir4(coord.x, coord.y, Direction4.E, value):
			start_dir = Direction4.E
			coord.x += 1
		else:
			outline.append(coord + top_left)
			outline.append(coord + bottom_left)
			outline.append(coord + bottom_right)
			outline.append(coord + top_right)
			return outline
		
		# corner_index points to the bottom right corner in direction dir
		corners = [bottom_right, bottom_left, top_left, top_right]
		
	var dir = start_dir
	var debug = 0

	while ++debug < 10000:
		# Shit, this is tricky....
		# Convention: We only add outline coords, which are NOT shared with the
		# next tile!
		
		if map.is_item_at_dir4(coord.x, coord.y, Tools.turn(dir, -windedness), value):
			dir = Tools.turn(dir, -windedness)
		elif map.is_item_at_dir4(coord.x, coord.y, dir, value):
			outline.append(coord + corners[dir])
		elif map.is_item_at_dir4(coord.x, coord.y, Tools.turn(dir, windedness), value):
			outline.append(coord + corners[dir])
			outline.append(coord + corners[Tools.turn(dir, windedness)])
			dir = Tools.turn(dir, windedness)
		else:
			outline.append(coord + corners[dir])
			outline.append(coord + corners[Tools.turn(dir, windedness)])
			outline.append(coord + corners[Tools.turn(dir, windedness * 2)])
			dir = Tools.turn(dir, windedness * 2)

		if coord.x == start.x && coord.y == start.y && dir == start_dir:
			break
		
		coord = Tools.step_dir(coord, dir)
	
	assert(debug < 10000)
	
	if optimize && outline.size() > 2:		
		var size = outline.size()
		
		var prev = outline.back()
		var current = outline[0]
		
		var i := 0
		
		while i < size:
			var next		
			if i < size - 1:
				next = outline[i + 1]
			else:
				next = outline[0]
			
			if current.x == prev.x and current.x == next.x:
				outline.remove_at(i)
				size -= 1
			elif current.y == prev.y and current.y == next.y:
				outline.remove_at(i)
				size -= 1
			else:
				i += 1
			
			prev = current
			current = next

	return outline

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

