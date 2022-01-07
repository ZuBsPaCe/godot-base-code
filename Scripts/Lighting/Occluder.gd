extends MeshInstance2D

class_name Occluder

@export var x1 := -200.0
@export var y1 := 0.0
@export var x2 := 200.0
@export var y2 := 0.0

# Godot uses clockwise winding order for front faces.
var points_cw := PackedVector2Array()
var closed := true
var shift := Vector2()

var occluder_material := preload("res://Lighting/Occluder.tres")

func _ready() -> void:
	# Points specified in CW Order.
#	var points = PoolVector2Array()
#
#	points.push_back(Vector2(x1, y1) + Vector2(960, 540))
#	points.push_back(Vector2(x2, y2) + Vector2(960, 540))
#
#	_create_mesh(points, false)

	if points_cw.size() == 0:
		print("Occluder points not set...")
		return
		
	_create_mesh(points_cw, closed)

func _create_mesh(points : PackedVector2Array, closed : bool) -> void:
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	#surface.set_material(mat)
	#surface.set_material(material_override)
	surface.set_material(occluder_material)
	
	
	# points are specified in cw winding order surrounding a (filled) polygon,
	# we need to reverse the order for the shadow to cast *into* the polygon.
	
	#var prev_point := points[points.size() - 1] if closed else points[0]
	var prev_point := points[0] if closed else points[points.size() - 1]
	
	for i in range(points.size() - 1 if closed else points.size() - 2, -1, -1):
		
		var current_point := points[i];
		
		surface.add_uv(Vector2(current_point.x, current_point.y) + shift);
		surface.add_uv2(Vector2(prev_point.x, prev_point.y) + shift);
		surface.add_vertex(Vector3(1, 0, 0)); # [1, 0] => current_point,   on occluder edge.
		
		surface.add_uv(Vector2(current_point.x, current_point.y) + shift);
		surface.add_uv2(Vector2(prev_point.x, prev_point.y) + shift);
		surface.add_vertex(Vector3(1, 1, 0)); # [1, 1] => current_point,   extruded. 
		
		surface.add_uv(Vector2(current_point.x, current_point.y) + shift);
		surface.add_uv2(Vector2(prev_point.x, prev_point.y) + shift);
		surface.add_vertex(Vector3(0, 0, 0)); # [0, 0] => prev_point,      on occluder edge.
		
		surface.add_uv(Vector2(current_point.x, current_point.y) + shift);
		surface.add_uv2(Vector2(prev_point.x, prev_point.y) + shift);
		surface.add_vertex(Vector3(0, 1, 0)); # [0, 1] => prev_point,      extruded.
		
		prev_point = current_point
		
		
	var vertex_index := 0
	for i in range(0 if closed else 1, points.size()):
		
		surface.add_index(vertex_index + 2); # [0, 0] => prev_point,      on occluder edge.
		surface.add_index(vertex_index + 3); # [0, 1] => prev_point,      extruded.
		surface.add_index(vertex_index + 0); # [1, 0] => current_point,   on occluder edge.
		
		surface.add_index(vertex_index + 0); # [1, 0] => current_point,   on occluder edge.
		surface.add_index(vertex_index + 3); # [0, 1] => prev_point,      extruded.
		surface.add_index(vertex_index + 1); # [1, 1] => current_point,   extruded. 
		
		vertex_index += 4

	mesh = surface.commit()
	
	#mesh.custom_aabb = AABB(Vector3.ONE, Vector3.ONE * 10000)
	#mesh.custom_aabb = AABB(Vector3(shift.x, shift.y, 0) + Vector3(32.0 * 32.0 * 0.5, 32.0 * 32.0 * 0.5, 1.0), Vector3(2048, 2048, 1.0))
	mesh.custom_aabb = AABB(Vector3.ZERO, Vector3(1024, 1024, 1.0))
