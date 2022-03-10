extends Node2D

const Direction4 := preload("res://Scripts/Tools/Direction4.gd").Direction4

@onready var camera := $Camera

@onready var flat_lighting := $FlatLighting
@onready var light := $FlatLight
@onready var tilemap_ceiling := $TileMapCeiling
@onready var debug_draw := $DebugDraw

func _ready() -> void:
	flat_lighting.register_light(light)
	
	var used_rect: Rect2 = tilemap_ceiling.get_used_rect()
	var map := Map.new(used_rect.size.x, used_rect.size.y)
	
	var to_tilemap := Vector2i(used_rect.position)
	var to_map := -to_tilemap
	
	map.set_all(0)
	
	var used_coords = tilemap_ceiling.get_used_cells(0)
	for coord in used_coords:
		var map_coord = coord + to_map
		map.set_item(map_coord.x, map_coord.y, 1)
	
	var wall_islands := [] 
	var floor_islands := [] 
	for y in map.height:
		for x in map.width:
			if map.get_item(x, y) == 1:
				wall_islands.append(get_island(map, x, y, 1, 2))
			elif map.get_item(x, y) == 0:
				floor_islands.append(get_island(map, x, y, 0, -1))
	
	print("%s Wall Islands found" % wall_islands.size())
	print("%s Floor Islands found" % floor_islands.size())
	
	var tile_size := Vector2i(64, 64)
	
	for island in wall_islands:	
		var outline := get_outline(map, island[0].x, island[0].y, 1, 2, true)

		print("Outline size: %s" % outline.size())
		var color := Color()
		color = color.from_hsv(randf(), 1.0, 1.0)

		for i in outline.size():
			var from = outline[i]
			var to = outline[i + 1] if i + 1 < outline.size() else outline[0]

			from = (from + to_tilemap) * tile_size
			to = (to + to_tilemap) * tile_size
			
			debug_draw.add_line(from, to, color, 8)
			debug_draw.add_circle(from, 8, color)
			
		for i in outline.size():
			outline[i] = (outline[i] + to_tilemap) * 64.0
		
		flat_lighting.add_occluder_points(Vector2.ZERO, outline)
	
	for island in floor_islands:
		var outline := get_outline(map, island[0].x, island[0].y, -1, -1, true)

		print("Outline size: %s" % outline.size())
		var color := Color()
		color = color.from_hsv(randf(), 1.0, 1.0)

		for i in outline.size():
			var from = outline[i]
			var to = outline[i + 1] if i + 1 < outline.size() else outline[0]

			from = (from + to_tilemap) * tile_size
			to = (to + to_tilemap) * tile_size
			
			debug_draw.add_line(from, to, color, 8)
			debug_draw.add_circle(from, 8, color)
		
		for i in outline.size():
			outline[i] = (outline[i] + to_tilemap) * 64.0
		
		flat_lighting.add_occluder_points(Vector2.ZERO, outline)
		
	for island in wall_islands:
		var coord = (island[0] + to_tilemap) * tile_size
		debug_draw.add_rect(Rect2(coord, tile_size), Color.RED)
	
	for island in floor_islands:
		var coord = (island[0] + to_tilemap) * tile_size
		debug_draw.add_rect(Rect2(coord, tile_size), Color.GRAY)
	

func get_outline(map: Map, x: int, y: int, windedness: int, value: int, optimize: bool) -> Array:
	assert(windedness == 1 or windedness == -1)
	
	# Important: We assume, that x/y starts at the topmost row's first tile from the left of the island.
	
	var top_right := Vector2i(1, 0)
	var top_left := Vector2i(0, 0)
	var bottom_left := Vector2i(0, 1)
	var bottom_right := Vector2i(1, 1)
	
	var corners : Array
	
	var start := Vector2i(x, y)
	var coord := start
	
	var outline := []
	var start_dir = null
	
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



func get_island(map: Map, x: int, y: int, from_value: int, to_value: int) -> Array:

	var start_coord := Vector2i(x, y)
	var heads := [start_coord]

	var island := [start_coord]	
	map.set_item(start_coord.x, start_coord.y, to_value)

	var checks := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

	while !heads.is_empty():
		var coord: Vector2i = heads.pop_back()

		for check in checks:
			var check_coord := coord + check

			if map.get_item_if_valid(check_coord.x, check_coord.y) == from_value:
				island.append(check_coord)
				map.set_item(check_coord.x, check_coord.y, to_value)
				heads.append(check_coord)

	return island
	
	
func _process(_delta: float) -> void:
	var player_pos := get_global_mouse_position()
	
	player_pos.x = clamp(player_pos.x, -960, 960)
	player_pos.y = clamp(player_pos.y, -540, 540)
	
	camera.position = player_pos
	light.position = get_global_mouse_position()
	
