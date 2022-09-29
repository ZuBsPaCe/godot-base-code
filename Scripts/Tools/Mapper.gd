class_name Mapper
extends RefCounted



# Region of a map. Either rectangular or a circle within a rectangle.
# Other proxies can be placed inside of this proxy.
class Proxy:
	var type
	
	var children := []
	
	var is_rectangle : bool
	var is_circle : bool
	
	# Rectangle is set for all proxies.
	var min_x : int
	var min_y : int
	var width : int
	var height : int
	
	var quiet_zone : Rect2
	
	# Center+Radius is only set for circle proxies.
	# This is the TILE center. Add 0.5/0.5 for the real center.
	var center_x : int
	var center_y : int
	var radius : float
	
	var quiet_radius : float
	
	func _init(p_type):
		type = p_type
	
	func rectangle(p_min_x: int, p_min_y: int, p_width: int, p_height: int):
		assert(!is_rectangle && !is_circle)
		assert(p_width > 0 && p_height > 0)
		is_rectangle = true
		min_x = p_min_x
		min_y = p_min_y
		width = p_width
		height = p_height
		
		quiet_zone = Rect2(min_x - 1, min_y - 1, width + 2, height + 2)
	
	func circle(p_center_x: int, p_center_y: int, p_radius: float):
		assert(!is_rectangle && !is_circle)
		assert(p_radius > 0)
		is_circle = true
		center_x = p_center_x
		center_y = p_center_y
		radius = p_radius
		min_x = floor(center_x - radius)
		min_y = floor(center_y - radius)
		
		var max_x = floor(center_x + radius)
		var max_y = floor(center_y + radius)
		width = max_x - min_x + 1
		height = max_y - min_y + 1
		
		quiet_zone = Rect2(min_x - 1, min_y - 1, width + 2, height + 2)
		
		# 1.415 => Add tile diagonal which is sqrt(1 + 1)
		quiet_radius = ceil(radius) + 1.415

	func get_indexes(map: Map) -> PackedInt32Array:
		var indexes := PackedInt32Array()
		if is_rectangle:
			for y in range(min_y, min_y + height):
				for x in range(min_x, min_x + width):
					indexes.append(y * map.width + x)
		else:
			var r2 = radius * radius
			for y in range(min_y, min_y + height):
				for x in range(min_x, min_x + width):
					var diff_x = x - center_x
					var diff_y = y - center_y
					if diff_x * diff_x + diff_y * diff_y <= r2:
						indexes.append(y * map.width + x)
		
		return indexes
	
	func has_coord(x: int, y: int) -> bool:
		if x < min_x || y < min_y || x >= min_x + width || y >= min_y + height:
			return false
		
		if is_rectangle:
			return true
		
		var diff_x = x - center_x
		var diff_y = y - center_y
		var r2 = radius * radius
		return diff_x * diff_x + diff_y * diff_y <= r2


var _map
var _root_proxies := []


func _init():
	pass

func init(map, seed_num = 0):
	_map = map
	_root_proxies.clear()
	
	if seed_num == 0:
		randomize()
		seed_num = randi()
	
	#print("Seed %d" % seed_num)
	seed(seed_num)


func add_root_proxy(type, p_min_x: int, p_min_y: int, p_width: int, p_height: int) -> Proxy:
	assert(p_width > 0 && p_height > 0)
	
	var proxy := Proxy.new(type)
	proxy.rectangle(p_min_x, p_min_y, p_width, p_height)
	_root_proxies.append(proxy)
	return proxy


func place_rectangle_proxy(parent: Proxy, type, width: int, height: int, retries = 1) -> Proxy:
	assert(parent.is_rectangle)
	assert(width > 0 && height > 0)
	
	if width > parent.width || height > parent.height:
		return null
	
	var lower_x := parent.min_x
	var upper_x := parent.min_x + parent.width - width
	var range_x := upper_x - lower_x
	var lower_y := parent.min_y
	var upper_y := parent.min_y + parent.height - height
	var range_y := upper_y - lower_y
	
	var found_proxy = null
	
	for retry in retries:
		var rect := Rect2(
			lower_x + randi() % (range_x + 1),
			lower_y + randi() % (range_y + 1),
			width,
			height)
		
		var ok := true
		
		for child in parent.children:
			if _proxy_intersects_rect(child, rect):
				ok = false
				break
		
		if !ok:
			continue
		
		var x := int(rect.position.x)
		var y := int(rect.position.y)
		
		found_proxy = Proxy.new(type)
		found_proxy.rectangle(x, y, width, height)
		parent.children.append(found_proxy)
		
		break
	
	return found_proxy


func place_circle_proxy(parent: Proxy, type, radius: float, retries = 1) -> Proxy:
	assert(parent.is_rectangle)
	var lower_x := parent.min_x + int(floor(radius))
	var upper_x := parent.min_x + parent.width - 1 - int(floor(radius))
	var range_x := upper_x - lower_x
	var lower_y := parent.min_y + int(floor(radius))
	var upper_y := parent.min_y + parent.height - 1 - int(floor(radius))
	var range_y := upper_y - lower_y
	
	if range_x < 0 || range_y < 0:
		return null
	
	var found_proxy = null
	
	for retry in retries:
		var center_x := lower_x + randi() % (range_x + 1)
		var center_y := lower_y + randi() % (range_y + 1)
		
		var ok := true
		
		for child in parent.children:
			if _proxy_intersects_circle(child, int(center_x), int(center_y), int(radius)):
				ok = false
				break
		
		if !ok:
			continue
		
		found_proxy = Proxy.new(type)
		found_proxy.circle(center_x, center_y, radius)
		parent.children.append(found_proxy)
		
		break
	
	return found_proxy


enum ConnectAreasMethod {
	RANDOM_WALK,
	MANHATTAN
}

func connect_separate_areas(proxy: Proxy, area_types: Array, connect_type, method):
	while true:
		var areas := get_separate_areas(proxy, area_types)
		
		if areas.size() <= 1:
			break
		
		for area_indexes in areas:
			var index: int = area_indexes[randi() % area_indexes.size()]
			
			var random_walk_indexes := [index]
			
			while true:
				var p = _map.get_coord(index)
				var x: int = p[0]
				var y: int = p[1]
				
				var dir := randi() % 4
				
				while true:
					var found_dir := false
					
					match dir:
						0:
							if proxy.has_coord(x, y + 1):
								found_dir = true
								y += 1
						1:
							if proxy.has_coord(x + 1, y):
								found_dir = true
								x += 1
						2:
							if proxy.has_coord(x, y - 1):
								found_dir = true
								y -= 1
						3:
							if proxy.has_coord(x - 1, y):
								found_dir = true
								x -= 1
					
					if found_dir:
						break
						
					dir = (dir + 1) % 4
					continue
				
				index = y * _map.width + x
				
				random_walk_indexes.append(index)
				
				if _map.get_indexed_item(index) in area_types && !area_indexes.has(index):
					break
			
			if method == ConnectAreasMethod.RANDOM_WALK:
				for swap_index in random_walk_indexes:
					_map.set_indexed_item(swap_index, connect_type)
			
			elif method == ConnectAreasMethod.MANHATTAN:
				var current: Vector2i = _map.get_coord(random_walk_indexes.front())
				
				var end: Vector2i = _map.get_coord(random_walk_indexes.back())
				
				var step_x := int(sign(end.x - current.x))
				var step_y := int(sign(end.y - current.y))
				
				if randi() % 2 == 0:
					while current.x != end.x:
						_map.set_item(current, connect_type)
						current.x += step_x
					
					while current.y != end.y:
						_map.set_item(current, connect_type)
						current.y += step_y
				else:
					while current.y != end.y:
						_map.set_item(current, connect_type)
						current.y += step_y
					
					while current.x != end.x:
						_map.set_item(current, connect_type)
						current.x += step_x
	

func get_separate_areas(proxy: Proxy, area_types: Array) -> Array:
	var areas := []
	
	var seen_indexes := {}
	
	for y in range(proxy.min_y, proxy.min_y + proxy.height):
		for x in range(proxy.min_x, proxy.min_x + proxy.width):
			var index = y * _map.width + x
			if seen_indexes.has(index):
				continue
			
			if _map.get_item_xy(x, y) in area_types:
				var area_indexes := []
				_flood_fill_count(proxy, x, y, area_types, seen_indexes, area_indexes)
				areas.append(area_indexes)
	
	return areas


func count_separate_areas(proxy: Proxy, area_types: Array) -> int:
	return get_separate_areas(proxy, area_types).size()

func _flood_fill_count(proxy: Proxy, start_x, start_y, area_types: Array, seen_indexes: Dictionary, area_indexes: Array) -> void:
	var heads := [[start_x, start_y]]
	
	var start_index = start_y * _map.width + start_x
	seen_indexes[start_index] = true
	area_indexes.append(start_index)
	
	while !heads.is_empty():
		var head = heads.pop_front()
		var x: int = head[0]
		var y: int = head[1]
		
		for i in 4:
			var next_x: int
			var next_y: int
			
			match i:
				0:
					next_x = x
					next_y = y + 1
				1:
					next_x = x + 1
					next_y = y
				2:
					next_x = x
					next_y = y - 1
				3:
					next_x = x - 1
					next_y = y
					
			if !proxy.has_coord(next_x, next_y):
				continue
			
			var index = next_y * _map.width + next_x
			if seen_indexes.has(index):
				continue
		
			if _map.is_inside_xy(next_x, next_y):
				if _map.get_item_xy(next_x, next_y) in area_types:
					heads.append([next_x, next_y])
					seen_indexes[index] = true
					area_indexes.append(index)


func _proxy_intersects_rect(proxy: Proxy, rect: Rect2) -> bool:
	if proxy.is_rectangle:
		return proxy.quiet_zone.intersects(rect, true)
	
	if !proxy.quiet_zone.intersects(rect, true):
		return false
	
	return _circle_intersects_rect(proxy.center_x, proxy.center_y, proxy.quiet_radius, rect)
	

func _proxy_intersects_circle(proxy: Proxy, center_x: int, center_y: int, radius: int) -> bool:
	if proxy.is_circle:
		var diff_x = proxy.center_x - center_x
		var diff_y = proxy.center_y - center_y
		
		var combined_radii = proxy.quiet_radius + radius
		
		return diff_x * diff_x + diff_y * diff_y <= combined_radii * combined_radii
	
	return _circle_intersects_rect(center_x, center_y, radius, proxy.quiet_zone)

func _circle_intersects_rect(center_x: int, center_y: int, radius: float, rect: Rect2) -> bool:
	# https://stackoverflow.com/a/402010/998987
	var rect_center:Vector2 = rect.position + 0.5 * (rect.end - rect.position)
	
	var real_center_x: float = center_x + 0.5
	var real_center_y: float = center_y + 0.5
	
	var dist_x : float = abs(real_center_x - rect_center.x)
	var dist_y : float = abs(real_center_y - rect_center.y)
	
	if dist_x > rect.size.x / 2.0 + radius:
		return false
	
	if dist_y > rect.size.y / 2.0 + radius:
		return false
	
	if dist_x <= rect.size.x / 2.0:
		return true
		
	if dist_y <= rect.size.y / 2.0:
		return true
	
	var corner_dist_x := dist_x - rect.size.x / 2.0
	var corner_dist_y := dist_y - rect.size.y / 2.0
	return corner_dist_x * corner_dist_x + corner_dist_y * corner_dist_y <= radius * radius

func fill_tiles(proxy, tile):
	for index in proxy.get_indexes(_map):
		_map.set_indexed_item(index, tile)
