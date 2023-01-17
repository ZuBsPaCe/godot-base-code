extends Node2D

@export var _active := false

@export var _draw_grid := false
@export var _grid_tiles := Rect2i()
@export var _grid_size := Globals.TILE_SIZE

var _grid_color := Color(0.5, 1.0, 0.5, 0.5)

class DebugRect:
	var rect: Rect2
	var color: Color
	
	func _init(p_rect: Rect2, p_color: Color):
		rect = p_rect
		color = p_color

class DebugLine:
	var from: Vector2
	var to: Vector2
	var color: Color
	var width: float
	
	func _init(p_from: Vector2, p_to: Vector2, p_color: Color, p_width: float):
		from = p_from
		to = p_to
		color = p_color
		width = p_width

class DebugCircle:
	var center: Vector2
	var radius: float
	var color: Color
	
	func _init(p_center: Vector2, p_radius: float, p_color: Color):
		center = p_center
		radius = p_radius
		color = p_color


var _debug_rects := []
var _debug_lines := []
var _debug_circles := []

func add_rect(p_rect: Rect2, p_color: Color):
	_debug_rects.append(DebugRect.new(p_rect, p_color))
	queue_redraw()

func add_line(p_from: Vector2, p_to: Vector2, p_color: Color, p_width: float):
	_debug_lines.append(DebugLine.new(p_from, p_to, p_color, p_width))
	queue_redraw()
	
func add_circle(p_center: Vector2, p_radius: float, p_color: Color):
	_debug_circles.append(DebugCircle.new(p_center, p_radius, p_color))
	queue_redraw()

func _ready():
	if _active:
		z_index = 999
		queue_redraw()

func _draw():
	if !_active:
		return
	
	if _draw_grid:
		var start := Vector2.ZERO
		var end := Vector2.ZERO
		
		start.x = _grid_tiles.position.x * _grid_size
		end.x =  _grid_tiles.end.x * _grid_size
		
		for y in range(_grid_tiles.position.y, _grid_tiles.end.y + 1):
			start.y = y * _grid_size
			end.y = y * _grid_size
			draw_line(start, end, _grid_color, 2)
			
		start.y = _grid_tiles.position.y * _grid_size
		end.y =  _grid_tiles.end.y * _grid_size
		
		for x in range(_grid_tiles.position.x, _grid_tiles.end.x + 1):
			start.x = x * _grid_size
			end.x = x * _grid_size
			draw_line(start, end, _grid_color, 2)
	
	for debug_rect in _debug_rects:
		draw_rect(debug_rect.rect, debug_rect.color)
	
	for debug_line in _debug_lines:
		draw_line(debug_line.from, debug_line.to, debug_line.color, debug_line.width)
		
	for debug_circle in _debug_circles:
		draw_circle(debug_circle.center, debug_circle.radius, debug_circle.color)
		
	queue_redraw()

func clear():
	_debug_rects.clear()
	_debug_lines.clear()
	_debug_circles.clear()
	
	queue_redraw()
