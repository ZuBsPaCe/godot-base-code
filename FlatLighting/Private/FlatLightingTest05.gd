extends Node2D

var _target: Vector2

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	for i in 20:
		var pos := Vector2(randf() * 3000 - 1500, randf() * 3000 - 1500)
		var points := [
			Vector2(-100, -100) + Vector2(randf() * 80 - 40, randf() * 80 - 40),
			Vector2( 100, -100) + Vector2(randf() * 80 - 40, randf() * 80 - 40),
			Vector2( 100,  100) + Vector2(randf() * 80 - 40, randf() * 80 - 40),
			Vector2(-100,  100) + Vector2(randf() * 80 - 40, randf() * 80 - 40)]
		
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		for point in points:
#			st.set_color(Color(1, 0, 0))
#			st.set_uv(Vector2(0, 0))
			st.add_vertex(Vector3(point.x, point.y, 0))
		
		#st.index()
		st.add_index(0)
		st.add_index(1)
		st.add_index(2)

		st.add_index(2)
		st.add_index(0)
		st.add_index(3)
		
		var mesh_instance := MeshInstance2D.new()
		mesh_instance.mesh = st.commit()
		mesh_instance.position = pos
		mesh_instance.z_index = 10
		mesh_instance.modulate = Color.MIDNIGHT_BLUE
		
		mesh_instance.material = ShaderMaterial.new()
		mesh_instance.material.shader = load("res://FlatLighting/Shaders/SimpleLightAndArea.gdshader")
		mesh_instance.material.set_shader_parameter("light_tex", FlatLightingLocator.flat_lighting.get_texture())
		mesh_instance.material.set_shader_parameter("area_tex", FlatLightingLocator.flat_lighting.get_area_texture())
		
		
		add_child(mesh_instance)
		
		FlatLightingLocator.flat_lighting.register_occluder(pos, points, true, mesh_instance)
	
	for x in range(-20, 20):
		for y in range(-20, 20):
			if x == 0 && y == 0:
				continue
			var clone = $Background.duplicate()
			clone.position = Vector2(x * 512, y * 512)
			add_child(clone)
	
	$Background.material.set_shader_parameter("light_tex", FlatLightingLocator.flat_lighting.get_texture())
	$Background.material.set_shader_parameter("area_tex", FlatLightingLocator.flat_lighting.get_area_texture())

func _process(_delta):
	_update_target()
	$Camera2D.position = get_global_mouse_position()
	$FlatLight.position = get_global_mouse_position()
	$FlatArea.position = get_global_mouse_position()
	
	#$Camera2D.position = ($Camera2D.position + _target) * 0.5()
#
#	#$Camera2D.position = get_global_mouse_position() * 1.0
#	$Camera2D.position = -1.0 * (get_viewport().get_mouse_position() - Vector2(1920, 1080) * 0.5)
#
#	print($Camera2D.position)
#	pass

func _update_target():
	_target = (get_viewport().get_mouse_position() - Vector2(1920, 1080) * 0.5)
