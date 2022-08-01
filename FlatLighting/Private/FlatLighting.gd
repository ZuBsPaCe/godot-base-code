extends Node2D

# If real viewport is 1920, a downscale of 2 will lead to shadow viewport width
# of 960. So use values like 2, 4, 8, 16 and so on.
@export var shadow_viewport_downscale := 1

@export var extra_cull_margin := 1920. * 2.0

@export var _camera_path : NodePath
@export var _overlay_path : NodePath

@export var occluder_material: Material
@export var _shadow_overlay_material: Material

@export var use_custom_clear_color := false
@export var custom_clear_color := Color.BLACK

#@onready var _shadow_viewport_container: Node = $ShadowViewportContainer
@onready var light_viewport: SubViewport = $LightViewport
@onready var _light_camera: Camera2D = $LightViewport/LightCamera

@onready var _camera: Camera2D = get_node(_camera_path)
@onready var _overlay: Sprite2D

var _default_occluder_material := preload("Occluder.tres")

var _internal_light_shader := preload("InternalLight.gdshader")

var _private_dir: String



class FlatLightHandle:
	var global_position: Vector2		
	var radius: float		
	var texture: Texture2D
	var color: Color
	var owner: Node2D
	
	var internal_index := -1
	var internal_light: Sprite2D
	var shadow_viewport: SubViewport
	var shadow_camera: Camera3D
	
	var update_position := false
	var update_radius := false
	
class FlatOccluderHandle:
	var global_position: Vector2			
	var points_cw: Array
	var closed: bool
	var owner: Node2D
	
	var internal_occluder: MeshInstance3D
	var update_position := false
	

var _flat_lights := []
var _flat_occluders := []

var _register_light_queue := []
var _unregister_light_queue := []

var _register_occluder_queue := []
var _unregister_occluder_queue := []

var _shadow_viewports := []
var _unused_shadow_viewport_indexes := []

var _configuration_error := false

var _light_pos_array := []
var _light_radius_array := []

func _init():
	FlatLightingLocator.flat_lighting = self
	
func _ready():
	
#	var viewport_width = ProjectSettings.get("display/window/size/viewport_width")
#	var viewport_height = ProjectSettings.get("display/window/size/viewport_height")

	if use_custom_clear_color:
		$LightViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
		$LightViewport/CustomClearColor.visible = true
	else:
		$LightViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		$LightViewport/CustomClearColor.visible = false

	for child in get_children():
		if str(child.name).begins_with("ShadowViewport"):
			_unused_shadow_viewport_indexes.append(_shadow_viewports.size())
			_shadow_viewports.append(child)

			child.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
			child.render_target_update_mode = SubViewport.UPDATE_DISABLED
			
			_light_pos_array.append(Vector2.ZERO)
			_light_radius_array.append(0.0)

	_private_dir = get_script().resource_path.get_base_dir()
	
	if occluder_material == null:
		occluder_material = _default_occluder_material
	
#	if _shadow_overlay_material == null:
#		_shadow_overlay_material = load("res://FlatLighting/ShadowOverlay.tres")
		
	if _camera == null:
		printerr("FlatLighting: Camera not set")
		_configuration_error = true
	
	if _configuration_error:
		set_process(false)
		
		return
	
	if !_overlay_path.is_empty():
		_overlay = get_node(_overlay_path)
		_overlay.texture = light_viewport.get_texture()
		
	
#	if !is_equal_approx(float(_shadow_viewport.size.x) / _shadow_viewport.size.y, float(viewport_width) / viewport_height):
#		printerr("FlatLighting: ShadowViewport aspect ratio will be changed to viewport aspect ratio")
#
#	if _shadow_camera.size != viewport_height:
#		printerr("FlatLighting: ShadowCamera size will be changed to viewport height.")
#
#	if !_shadow_viewport.render_target_clear_mode == SubViewport.CLEAR_MODE_ALWAYS:
#		printerr("FlatLighting: ShadowViewport clear mode will be changed to ALWAYS")
#
#	if !_shadow_viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
#		printerr("FlatLighting: ShadowViewport update mode will be changed to UPDATE ALWAYS")
#
#	if !_shadow_camera.current:
#		printerr("FlatLighting: ShadowCamera is not current")
#
#	if _shadow_camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
#		printerr("FlatLighting: ShadowCamera projection must be ORTHOGONAL")
#
	update_viewport_size()

func get_camera_center() -> Vector2:
	# Determine camera center in global coords...
	# camera.global_position does not work with drag margins / smoothing it seems...
	# https://godotengine.org/qa/4750/get-center-of-the-current-camera2d?show=4753#a4753
	var vtrans := _camera.get_canvas_transform()
	var top_left := -vtrans.get_origin() / vtrans.get_scale()
	var viewport_size := _camera.get_viewport_rect().size
	var camera_center := top_left + 0.5 * viewport_size / vtrans.get_scale()
	return camera_center

func update_viewport_size():
	if _configuration_error:
		return

	var viewport_width = ProjectSettings.get("display/window/size/viewport_width")
	var viewport_height = ProjectSettings.get("display/window/size/viewport_height")

	light_viewport.size = Vector2(viewport_width / shadow_viewport_downscale, viewport_height / shadow_viewport_downscale)

#	_shadow_camera.size = viewport_height

func _process(_delta):		
	for handle in _register_light_queue:		
		if _unused_shadow_viewport_indexes.is_empty():
			continue
		
		var light_texture_size = handle.texture.get_size()
		
		# Works without frame delay...
		var shadow_viewport_index = _unused_shadow_viewport_indexes.pop_front()
		var shadow_viewport = _shadow_viewports[shadow_viewport_index]
		var shadow_camera = shadow_viewport.get_node("ShadowCamera")
		
		shadow_viewport.size = light_texture_size
		shadow_camera.size = shadow_viewport.size.y
				
		shadow_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		shadow_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		var internal_light_material := ShaderMaterial.new()
		
		internal_light_material.shader = _internal_light_shader
		internal_light_material.set_shader_param("light_tex", handle.texture)
		internal_light_material.set_shader_param("color", handle.color)
		
		var internal_light := Sprite2D.new()
		internal_light.name = "InternalLight"
		internal_light.texture = shadow_viewport.get_texture()
		internal_light.flip_v = true
		internal_light.material = internal_light_material
		internal_light.position = handle.global_position
		
		light_viewport.add_child(internal_light)
		
		handle.internal_index = shadow_viewport_index
		handle.internal_light = internal_light
		handle.shadow_viewport = shadow_viewport
		handle.shadow_camera = shadow_camera
		
		handle.update_position = true
		handle.update_radius = true

		_flat_lights.append(handle)
		
	_register_light_queue.clear()
	
	
	for handle in _unregister_light_queue:
		if handle.internal_index >= 0:
			handle.internal_light.queue_free()
			
			handle.shadow_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
			handle.shadow_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
			
			_unused_shadow_viewport_indexes.append(handle.internal_index)
		
		_flat_lights.erase(handle)
	
	_unregister_light_queue.clear()
	
	
	for handle in _register_occluder_queue:
		var mesh := _create_occluder_mesh(handle.points_cw, handle.closed)
		
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.cast_shadow = false
		mesh_instance.mesh = mesh
		mesh_instance.material_override = occluder_material
		
		# WARNING: AABB specification is a bit strange. It seems, we not to specify the
		# to top-left corner as argument 1 (position) with an extent to right/down.
		# But also keep in mind, that we flip the viewport in shadow overlay.
		# Therefore, extra cull margin is a lot simpler!
		#mesh.custom_aabb = AABB(Vector3(-16, -16, 0), Vector3(0, 0, 10.0))
		
		mesh_instance.extra_cull_margin = extra_cull_margin
			
		mesh_instance.name = "Occluder Mesh"
		
		handle.internal_occluder = mesh_instance
		
		_shadow_viewports[0].add_child(mesh_instance)
		
		handle.update_position = true
		
		_flat_occluders.append(handle)
	
	_register_occluder_queue.clear()
	
	for handle in _unregister_occluder_queue:
		handle.internal_occluder.queue_free() 
		_flat_occluders.erase(handle)
	
	_unregister_occluder_queue.clear()
		

	var camera_center := get_camera_center()
	
	var update_light_pos_array := false
	var update_light_radius_array := true
	
	for handle in _flat_lights:
		if handle.internal_index < 0:
			continue
		
		if handle.owner != null and handle.global_position != handle.owner.global_position:
			handle.global_position = handle.owner.global_position
			handle.update_position = true
			
		if handle.update_position:
			handle.shadow_camera.position = Vector3(handle.global_position.x, handle.global_position.y, handle.internal_index + 1)
			
			_light_pos_array[handle.internal_index] = handle.global_position
			handle.update_position = false
			update_light_pos_array = true
		
		handle.internal_light.position = handle.global_position - get_camera_center()
		
		if handle.update_radius:
			_light_radius_array[handle.internal_index] = handle.radius
			handle.update_radius = false
			update_light_radius_array = true
	
	if update_light_pos_array:
		occluder_material.set_shader_param("light_pos_array", _light_pos_array)
		
	if update_light_radius_array:
		occluder_material.set_shader_param("light_radius_array", _light_radius_array)
	
	for handle in _flat_occluders:
		if handle.owner != null and handle.global_position != handle.owner.global_position:
			handle.global_position = handle.owner.global_position
			handle.update_position = true
		
		if handle.update_position:
			handle.internal_occluder.transform.origin = Vector3(handle.global_position.x, handle.global_position.y, 0.0)
			handle.update_position = false
	
func _update_viewport_size(shadow_viewport: SubViewport, light_texture_size: Vector2):
	shadow_viewport.size = Vector2(light_texture_size.x / shadow_viewport_downscale, light_texture_size.y / shadow_viewport_downscale)

func get_texture() -> Texture2D:
	return $LightViewport.get_texture()

func register_light(global_position: Vector2, radius: float, texture: Texture, color: Color, owner: Node2D = null) -> Object:
	var handle := FlatLightHandle.new()
		
	handle.global_position = global_position
	handle.radius = radius
	handle.texture = texture
	handle.color = color
	handle.owner = owner
	
	_register_light_queue.append(handle)
	
	return handle

func unregister_light(handle):
	_unregister_light_queue.append(handle)

func update_light_radius(handle, radius: float):
	handle.radius = radius
	handle.update_radius = true
	
func register_occluder(global_position: Vector2, points_cw: Array, closed: bool, owner: Node2D = null):
	var handle := FlatOccluderHandle.new()
	
	handle.global_position = global_position
	handle.points_cw = points_cw
	handle.closed = closed
	handle.owner = owner
	
	_register_occluder_queue.append(handle)
	
func unregister_occluder(handle):
	_unregister_occluder_queue.append(handle)
	
func get_occluder_quad(tile_size: float) -> Array:
	
	var half_size := tile_size * 0.5
	
	var points_cw := []
	points_cw.append(Vector2(-half_size, -half_size))
	points_cw.append(Vector2(half_size, -half_size))
	points_cw.append(Vector2(half_size, half_size))
	points_cw.append(Vector2(-half_size, half_size))
	
	return points_cw
	

func clear_occluders():
	for handle in _flat_occluders:
		handle.internal_occluder.queue_free()
		handle.internal_occluder = null
	
	_flat_occluders.clear()


func _create_occluder_mesh(points_cw: Array, closed: bool) -> Mesh:	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
#	surface.set_material(p_occluder_material)
	
	
	# Points are specified in cw winding order surrounding a (filled) polygon,
	# we need to reverse the order for the shadow to cast *into* the polygon.
	
	var prev_point : Vector2 = points_cw[0] if closed else points_cw[points_cw.size() - 1]
	
	for i in range(points_cw.size() - 1 if closed else points_cw.size() - 2, -1, -1):
		
		var current_point : Vector2 = points_cw[i];
		
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
	for i in range(0 if closed else 1, points_cw.size()):
		
		surface.add_index(vertex_index + 2); # [0, 0] => prev_point,      on occluder edge.
		surface.add_index(vertex_index + 3); # [0, 1] => prev_point,      extruded.
		surface.add_index(vertex_index + 0); # [1, 0] => current_point,   on occluder edge.
		
		surface.add_index(vertex_index + 0); # [1, 0] => current_point,   on occluder edge.
		surface.add_index(vertex_index + 3); # [0, 1] => prev_point,      extruded.
		surface.add_index(vertex_index + 1); # [1, 1] => current_point,   extruded. 
		
		vertex_index += 4

	return surface.commit()
