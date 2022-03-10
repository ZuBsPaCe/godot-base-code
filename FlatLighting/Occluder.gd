extends MeshInstance3D

var _occluder_material := preload("res://FlatLighting/Occluder.tres")

func _ready():
	if mesh == null:
		printerr("FlatLighting: Occluder.create_mesh() was not called")
		return

func create_mesh(p_pos3d: Vector3, p_points: Array, p_closed: bool, p_extra_cull_margin: float) -> void:
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(_occluder_material)
	
	
	# Points are specified in cw winding order surrounding a (filled) polygon,
	# we need to reverse the order for the shadow to cast *into* the polygon.
	
	var prev_point : Vector2 = p_points[0] if p_closed else p_points[p_points.size() - 1]
	
	for i in range(p_points.size() - 1 if p_closed else p_points.size() - 2, -1, -1):
		
		var current_point : Vector2 = p_points[i];
		
		surface.set_uv(Vector2(current_point.x, current_point.y));
		surface.set_uv2(Vector2(prev_point.x, prev_point.y));
		surface.add_vertex(Vector3(1, 0, 0)); # [1, 0] => current_point,   on occluder edge.
		
		surface.set_uv(Vector2(current_point.x, current_point.y));
		surface.set_uv2(Vector2(prev_point.x, prev_point.y));
		surface.add_vertex(Vector3(1, 1, 0)); # [1, 1] => current_point,   extruded. 
		
		surface.set_uv(Vector2(current_point.x, current_point.y));
		surface.set_uv2(Vector2(prev_point.x, prev_point.y));
		surface.add_vertex(Vector3(0, 0, 0)); # [0, 0] => prev_point,      on occluder edge.
		
		surface.set_uv(Vector2(current_point.x, current_point.y));
		surface.set_uv2(Vector2(prev_point.x, prev_point.y));
		surface.add_vertex(Vector3(0, 1, 0)); # [0, 1] => prev_point,      extruded.
		
		prev_point = current_point
		
		
	var vertex_index := 0
	for i in range(0 if p_closed else 1, p_points.size()):
		
		surface.add_index(vertex_index + 2); # [0, 0] => prev_point,      on occluder edge.
		surface.add_index(vertex_index + 3); # [0, 1] => prev_point,      extruded.
		surface.add_index(vertex_index + 0); # [1, 0] => current_point,   on occluder edge.
		
		surface.add_index(vertex_index + 0); # [1, 0] => current_point,   on occluder edge.
		surface.add_index(vertex_index + 3); # [0, 1] => prev_point,      extruded.
		surface.add_index(vertex_index + 1); # [1, 1] => current_point,   extruded. 
		
		vertex_index += 4

	mesh = surface.commit()
	
	# WARNING: AABB specification is a bit strange. It seems, we not to specify the
	# to top-left corner as argument 1 (position) with an extent to right/down.
	# But also keep in mind, that we flip the viewport in shadow overlay.
	# Therefore, extra cull margin is a lot simpler!
	#mesh.custom_aabb = AABB(Vector3(-16, -16, 0), Vector3(0, 0, 10.0))
	
	extra_cull_margin = p_extra_cull_margin
		
	transform.origin = p_pos3d
