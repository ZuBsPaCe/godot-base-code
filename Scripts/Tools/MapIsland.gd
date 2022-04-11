class_name MapIsland
extends RefCounted

var item: int
var map_coords: MapCoords

func _init(p_item: int, p_map_coords: MapCoords):
	item = p_item
	map_coords = p_map_coords
	

func _to_string():
	return "Item: %d  Coords: %d" % [item, map_coords.size()] 
