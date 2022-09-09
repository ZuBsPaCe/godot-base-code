class_name MapIsland
extends RefCounted

const Direction4 := preload("res://Scripts/Tools/Direction4.gd").Direction4

var item: int
var map_coords: MapCoords
var top_left_coord: Vector2i

func _init(p_item: int, p_map_coords: MapCoords, p_top_left_coord: Vector2i):
	item = p_item
	map_coords = p_map_coords
	top_left_coord = p_top_left_coord
	

func _to_string():
	return "Item: %d  Coords: %d" % [item, map_coords.size()] 


func get_outline(windedness: int, optimize = true) -> Array[Vector2]:
	assert(windedness == 1 or windedness == -1)
	
	# Important: We assume, that x/y starts at the topmost row, on its leftmost tile.
	
	var top_right := Vector2i(1, 0)
	var top_left := Vector2i(0, 0)
	var bottom_left := Vector2i(0, 1)
	var bottom_right := Vector2i(1, 1)
	
	var corners : Array
	
	var start := top_left_coord
	var coord := start
	
	var outline := []
	var start_dir = null
	
	if windedness == 1:
		# Create clockwise outline
	
		if map_coords.has_coord_at_dir(coord, Direction4.E):
			start_dir = Direction4.E
			coord.x += 1
		elif map_coords.has_coord_at_dir(coord, Direction4.S):
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
		
		if map_coords.has_coord_at_dir(coord, Direction4.S):
			start_dir = Direction4.S
			coord.y += 1
		elif map_coords.has_coord_at_dir(coord, Direction4.E):
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
		
		if map_coords.has_coord_at_dir(coord, Tools.turn(dir, -windedness)):
			dir = Tools.turn(dir, -windedness)
		elif map_coords.has_coord_at_dir(coord, dir):
			outline.append(coord + corners[dir])
		elif map_coords.has_coord_at_dir(coord, Tools.turn(dir, windedness)):
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
