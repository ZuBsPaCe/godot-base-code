extends Node2D

# If real viewport is 1920, a downscale of 2 will lead to shadow viewport width
# of 960. So use values like 2, 4, 8, 16 and so on.
@export var shadow_viewport_downscale := 1

@export var extra_cull_margin := 1920. * 2.0

@export var _camera_path : NodePath
@export var _overlay_path : NodePath

@export var occluder_material: Material

@export var use_custom_clear_color := false
@export var custom_clear_color := Color.BLACK

@export var _debug_occluders := false

@onready var light_viewport: SubViewport = $LightViewport
@onready var area_viewport: SubViewport = $AreaViewport

@onready var _camera: Camera2D = get_node(_camera_path)
@onready var _overlay: Sprite2D


var _default_occluder_material := preload("Occluder.tres")

var _internal_light_shader := preload("InternalLight.gdshader")
var _internal_area_shader := preload("InternalArea.gdshader")
var _internal_area_material: ShaderMaterial


class ShadowViewportHandle:
	var internal_index := -1
	var internal_light: Sprite2D
	var shadow_viewport: SubViewport
	var shadow_camera: Camera3D
	var in_use := false


class FlatLightHandle:
	var global_pos: Vector2
	var radius: float
	var texture: Texture2D
	var color: Color
	var priority: int
	var node: Node2D
	
	var shadow_viewport_handle: ShadowViewportHandle
	
	var update_position := false
	var update_radius := false


class FlatOccluderHandle:
	var global_pos: Vector2
	var points_cw: Array
	var closed: bool
	var node: Node2D
	
	var internal_occluder: MeshInstance3D
	var update_position := false


class AreaHandle:
	var global_pos: Vector2
	var texture: Texture2D
	var node: Node2D
	
	var internal_area: Sprite2D
	
	var update_position := false


var _shadow_viewport_handles := []

var _flat_light_handles := []
var _flat_occluder_handles := []

var _area_handles := []

var _register_flat_light_queue := []
var _unregister_flat_light_queue := []

var _register_occluder_queue := []
var _unregister_occluder_queue := []

var _register_area_queue := []
var _unregister_area_queue := []


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
		$LightViewport/ClearCanvasLayer.visible = true
		$LightViewport/ClearCanvasLayer/CustomClearColor.color = custom_clear_color
		
		$AreaViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
		$AreaViewport/ClearCanvasLayer.visible = true
		$AreaViewport/ClearCanvasLayer/CustomClearColor.color = custom_clear_color
	else:
		$LightViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		$LightViewport/ClearCanvasLayer.visible = false
		
		$AreaViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		$AreaViewport/ClearCanvasLayer.visible = false

	for child in get_children():
		if str(child.name).begins_with("ShadowViewport"):
			# Only pre-instantiated viewports work without frame delay...
			
			var shadow_viewport = child
			var shadow_viewport_index = _shadow_viewport_handles.size()
			
			_light_pos_array.append(Vector2.ZERO)
			_light_radius_array.append(0.0)

			var shadow_camera = shadow_viewport.get_node("ShadowCamera")
			
			shadow_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
			shadow_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
			
			var internal_light_material := ShaderMaterial.new()
			
			internal_light_material.shader = _internal_light_shader
			
			var internal_light := Sprite2D.new()
			internal_light.visible = false
			internal_light.name = "InternalLight"
			internal_light.texture = shadow_viewport.get_texture()
			internal_light.flip_v = true
			internal_light.material = internal_light_material
			
			light_viewport.add_child(internal_light)
			
			var handle := ShadowViewportHandle.new()
			
			handle.internal_index = shadow_viewport_index
			handle.internal_light = internal_light
			handle.shadow_viewport = shadow_viewport
			handle.shadow_camera = shadow_camera

			_shadow_viewport_handles.append(handle)
	
	if occluder_material == null:
		occluder_material = _default_occluder_material
	
#	if _shadow_overlay_material == null:
#		_shadow_overlay_material = load("res://FlatLighting/ShadowOverlay.tres")
	
	_internal_area_material = ShaderMaterial.new()
	_internal_area_material.shader = _internal_area_shader
	
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
	area_viewport.size = Vector2(viewport_width / shadow_viewport_downscale, viewport_height / shadow_viewport_downscale)

#	_shadow_camera.size = viewport_height

func _start_shadow_viewport(flat_light_handle: FlatLightHandle):
	assert(flat_light_handle.shadow_viewport_handle == null)
	
	var light_texture_size = flat_light_handle.texture.get_size()
	
	var shadow_viewport_handle: ShadowViewportHandle
	
	for current_shadow_viewport_handle in _shadow_viewport_handles:
		if current_shadow_viewport_handle.in_use:
			continue
		
		var current_size = current_shadow_viewport_handle.shadow_viewport.size
		
		if current_size.x == light_texture_size.x and current_size.y == light_texture_size.y:
			shadow_viewport_handle = current_shadow_viewport_handle
			break
		
		if shadow_viewport_handle == null:
			shadow_viewport_handle = current_shadow_viewport_handle
	
	shadow_viewport_handle.in_use = true
	
	var shadow_viewport: SubViewport = shadow_viewport_handle.shadow_viewport
	var shadow_camera: Camera3D = shadow_viewport_handle.shadow_camera
	
	shadow_viewport.size = light_texture_size
	shadow_camera.size = light_texture_size.y
	
	shadow_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	shadow_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	var internal_light: Sprite2D = shadow_viewport_handle.internal_light
	var internal_light_material: ShaderMaterial = internal_light.material
	
#	internal_light.texture = shadow_viewport.get_texture()
	internal_light_material.set_shader_parameter("light_tex", flat_light_handle.texture)
	internal_light_material.set_shader_parameter("color", flat_light_handle.color)
	
	internal_light.visible = true
	
	flat_light_handle.update_position = true
	flat_light_handle.update_radius = true
	
	
	shadow_viewport_handle.internal_light.visible = true

	flat_light_handle.shadow_viewport_handle = shadow_viewport_handle


func _stop_shadow_viewport(flat_light_handle: FlatLightHandle):
	assert(flat_light_handle.shadow_viewport_handle != null)
	
	var shadow_viewport_handle: ShadowViewportHandle = flat_light_handle.shadow_viewport_handle
	
	var shadow_viewport: SubViewport = shadow_viewport_handle.shadow_viewport
	
	shadow_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	shadow_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	var internal_light: Sprite2D = shadow_viewport_handle.internal_light
	internal_light.visible = false
	
	shadow_viewport_handle.in_use = false
	
	flat_light_handle.shadow_viewport_handle = null
	
	

func _process(_delta):
	var flat_lights_changed = !_register_flat_light_queue.is_empty() or !_unregister_flat_light_queue.is_empty()
	
	if flat_lights_changed:
		for flat_light_handle in _register_flat_light_queue:
			assert(flat_light_handle not in _flat_light_handles)
			var priority_index := 0
			for existing_flat_light in _flat_light_handles:
				if flat_light_handle.priority > existing_flat_light.priority:
					break
				priority_index += 1
			
			_flat_light_handles.insert(priority_index, flat_light_handle)
		
		_register_flat_light_queue.clear()
		
		for flat_light_handle in _unregister_flat_light_queue:
			assert(flat_light_handle in _flat_light_handles)
			if flat_light_handle.shadow_viewport_handle != null:
				_stop_shadow_viewport(flat_light_handle)
			_flat_light_handles.erase(flat_light_handle)
		_unregister_flat_light_queue.clear()
		
		var flat_light_index = _flat_light_handles.size() - 1
		while flat_light_index >= 0:
			var flat_light_handle = _flat_light_handles[flat_light_index]
			if flat_light_index >= 8:
				print_debug("Shadow viewports depleted")
				if flat_light_handle.shadow_viewport_handle != null:
					_stop_shadow_viewport(flat_light_handle)
			else:
				if flat_light_handle.shadow_viewport_handle == null:
					_start_shadow_viewport(flat_light_handle)
			
			flat_light_index -= 1
	
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
		
		_shadow_viewport_handles[0].shadow_viewport.add_child(mesh_instance)
		
		handle.update_position = true
		
		_flat_occluder_handles.append(handle)
	
	_register_occluder_queue.clear()
	
	for handle in _unregister_occluder_queue:
		handle.internal_occluder.queue_free() 
		_flat_occluder_handles.erase(handle)
	
	_unregister_occluder_queue.clear()
	
	
	for handle in _register_area_queue:
		var internal_area := Sprite2D.new()
		internal_area.name = "InternalArea"
		internal_area.texture = handle.texture
		internal_area.flip_v = true
		internal_area.material = _internal_area_material
		
		handle.internal_area = internal_area
		
		area_viewport.add_child(internal_area)
		_area_handles.append(handle)
	
	_register_area_queue.clear()
	
	for handle in _unregister_area_queue:
		handle.internal_area.queue_free()
		_area_handles.erase(handle)
	
	_unregister_area_queue.clear()

	var camera_center := get_camera_center()
	
	var update_light_pos_array := false
	var update_light_radius_array := false
	
	for flat_light_handle in _flat_light_handles:
		if flat_light_handle.shadow_viewport_handle == null:
			continue
		
		var shadow_viewport_handle: ShadowViewportHandle = flat_light_handle.shadow_viewport_handle
		
		if flat_light_handle.node != null and flat_light_handle.global_pos != flat_light_handle.node.global_position:
			flat_light_handle.global_pos = flat_light_handle.node.global_position
			flat_light_handle.update_position = true
			
		if flat_light_handle.update_position:
			shadow_viewport_handle.shadow_camera.position = Vector3(flat_light_handle.global_pos.x, flat_light_handle.global_pos.y, shadow_viewport_handle.internal_index + 1)
			
			_light_pos_array[shadow_viewport_handle.internal_index] = flat_light_handle.global_pos
			flat_light_handle.update_position = false
			update_light_pos_array = true
		
		# Must be updated each frame!
		shadow_viewport_handle.internal_light.position = flat_light_handle.global_pos - camera_center
		
		if flat_light_handle.update_radius:
			_light_radius_array[shadow_viewport_handle.internal_index] = flat_light_handle.radius
			flat_light_handle.update_radius = false
			update_light_radius_array = true
	
	if update_light_pos_array:
		occluder_material.set_shader_parameter("light_pos_array", _light_pos_array)
		
	if update_light_radius_array:
		occluder_material.set_shader_parameter("light_radius_array", _light_radius_array)
	
	for handle in _flat_occluder_handles:
		if handle.node != null and handle.global_pos != handle.node.global_position:
			handle.global_pos = handle.node.global_position
			handle.update_position = true
		
		if handle.update_position:
			handle.internal_occluder.transform.origin = Vector3(handle.global_pos.x, handle.global_pos.y, 0.0)
			handle.update_position = false

	for area_handle in _area_handles:
		if area_handle.node != null and area_handle.global_pos != area_handle.node.global_position:
			area_handle.global_pos = area_handle.node.global_position
			area_handle.update_position = false
			
		# Must be updated each frame!
		area_handle.internal_area.position = area_handle.global_pos - camera_center
	
	if _debug_occluders:
		z_index = 999
		queue_redraw()

func _draw():
	if !_debug_occluders:
		return
		
	for handle in _flat_occluder_handles:
		for i in handle.points_cw.size() - 1:
			draw_line(handle.points_cw[i], handle.points_cw[i + 1], Color.DEEP_PINK, 3)
		if handle.closed:
			draw_line(handle.points_cw[handle.points_cw.size() - 1], handle.points_cw[0], Color.DEEP_PINK, 3)

func get_texture() -> Texture2D:
	return $LightViewport.get_texture()

func get_area_texture() -> Texture2D:
	return $AreaViewport.get_texture()

func register_light(global_pos: Vector2, radius: float, texture: Texture, color: Color, priority: int, node: Node2D = null) -> Object:
	var handle := FlatLightHandle.new()
		
	handle.global_pos = global_pos
	handle.radius = radius
	handle.texture = texture
	handle.color = color
	handle.priority = priority
	handle.node = node
	
	_register_flat_light_queue.append(handle)
	
	return handle

func unregister_light(handle):
	_unregister_flat_light_queue.append(handle)

func update_light_radius(handle, radius: float):
	handle.radius = radius
	handle.update_radius = true

func register_occluder(global_pos: Vector2, points_cw: Array, closed: bool, node: Node2D = null) -> Object:
	var handle := FlatOccluderHandle.new()
	
	handle.global_pos = global_pos
	handle.points_cw = points_cw
	handle.closed = closed
	handle.node = node
	
	_register_occluder_queue.append(handle)
	
	return handle
	
func unregister_occluder(handle):
	_unregister_occluder_queue.append(handle)


func register_area(global_pos: Vector2, texture: Texture, node: Node2D = null) -> Object:
	var handle := AreaHandle.new()
	
	handle.global_pos = global_pos
	handle.texture = texture
	handle.node = node
	
	_register_area_queue.append(handle)
	
	return handle

func unregister_area(handle):
	_unregister_area_queue.append(handle)


func get_occluder_quad(tile_size: float) -> Array:
	
	var half_size := tile_size * 0.5
	
	var points_cw := []
	points_cw.append(Vector2(-half_size, -half_size))
	points_cw.append(Vector2(half_size, -half_size))
	points_cw.append(Vector2(half_size, half_size))
	points_cw.append(Vector2(-half_size, half_size))
	
	return points_cw
	

func clear_occluders():
	for handle in _flat_occluder_handles:
		handle.internal_occluder.queue_free()
		handle.internal_occluder = null
	
	_flat_occluder_handles.clear()


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
