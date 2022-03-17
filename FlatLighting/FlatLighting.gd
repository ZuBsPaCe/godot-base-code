extends Node2D

# If real viewport is 1920, a downscale of 2 will lead to shadow viewport width
# of 960. So use values like 2, 4, 8, 16 and so on.
@export var shadow_viewport_downscale := 1

@export var extra_cull_margin := 1920. * 2.0

@export var _shadow_viewport_path : NodePath
@export var _shadow_camera_path : NodePath
@export var _shadow_overlay_path : NodePath
@export var _camera_path : NodePath

@export var occluder_material: Material
@export var _shadow_overlay_material: Material

@onready var _shadow_viewport : SubViewport = get_node(_shadow_viewport_path)
@onready var _shadow_camera : Camera3D = get_node(_shadow_camera_path)
@onready var _shadow_overlay : Sprite2D = get_node(_shadow_overlay_path)
@onready var _camera : Camera2D = get_node(_camera_path)

var _occluder_mesh_scene := preload("res://FlatLighting/OccluderMesh.tscn")

var _lights := []

var _configuration_error := false

func _ready():	
	var viewport_width = ProjectSettings.get("display/window/size/viewport_width")
	var viewport_height = ProjectSettings.get("display/window/size/viewport_height")
	
	if occluder_material == null:
		occluder_material = load("res://FlatLighting/Occluder.tres")
	
	if _shadow_overlay_material == null:
		_shadow_overlay_material = load("res://FlatLighting/ShadowOverlay.tres")
	
	if _shadow_viewport == null:
		printerr("FlatLighting: ShadowViewport not set")
		_configuration_error = true
		
	if _shadow_camera == null:
		printerr("FlatLighting: ShadowCamera not set")
		_configuration_error = true
		
	if _camera == null:
		printerr("FlatLighting: Camera not set")
		_configuration_error = true
	
	if _configuration_error:
		set_process(false)
		
		if _shadow_overlay != null:
			_shadow_overlay.visible = false
		return
	
	if _shadow_overlay == null:
		print("FlatLighting: ShadowOverlay not set")
	else:
		if _shadow_overlay.material == null:
			_shadow_overlay.material = _shadow_overlay_material
		
		if _shadow_overlay.texture == null:
			_shadow_overlay.flip_v = true
			
			_shadow_overlay.texture = _shadow_viewport.get_texture()
	
	if !is_equal_approx(float(_shadow_viewport.size.x) / _shadow_viewport.size.y, float(viewport_width) / viewport_height):
		printerr("FlatLighting: ShadowViewport aspect ratio will be changed to viewport aspect ratio")
		
	if _shadow_camera.size != viewport_height:
		printerr("FlatLighting: ShadowCamera size will be changed to viewport height.")
		
	if !_shadow_viewport.render_target_clear_mode == SubViewport.CLEAR_MODE_ALWAYS:
		printerr("FlatLighting: ShadowViewport clear mode will be changed to ALWAYS")
		
	if !_shadow_viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
		printerr("FlatLighting: ShadowViewport update mode will be changed to UPDATE ALWAYS")

	if !_shadow_camera.current:
		printerr("FlatLighting: ShadowCamera is not current")
		
	if _shadow_camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		printerr("FlatLighting: ShadowCamera projection must be ORTHOGONAL")

	update_viewport_size()
	
func update_viewport_size():
	if _configuration_error:
		return
		
	var viewport_width = ProjectSettings.get("display/window/size/viewport_width")
	var viewport_height = ProjectSettings.get("display/window/size/viewport_height")
	
	_shadow_viewport.size = Vector2(viewport_width / shadow_viewport_downscale, viewport_height / shadow_viewport_downscale)
	
	_shadow_camera.size = viewport_height

func _process(_delta):		
	# Determine camera center in global coords...
	# camera.global_position does not work with drag margins / smoothing it seems...
	# https://godotengine.org/qa/4750/get-center-of-the-current-camera2d?show=4753#a4753
	var vtrans := _camera.get_canvas_transform()
	var top_left := -vtrans.get_origin() / vtrans.get_scale()
	var viewport_size := _camera.get_viewport_rect().size
	var camera_center := top_left + 0.5 * viewport_size / vtrans.get_scale()
	
	
	var scale_up := Vector2(viewport_size.x / _shadow_viewport.size.x, viewport_size.y / _shadow_viewport.size.y)
	#var scale_down := Vector2(_shadow_viewport.size.x / viewport_size.x, _shadow_viewport.size.y / viewport_size.y)
	
	_shadow_camera.position = Vector3(camera_center.x, camera_center.y, 2.0)
	
	_shadow_overlay.scale = scale_up
	_shadow_overlay.position = camera_center

	for light in _lights:
		occluder_material.set_shader_param("light_pos", light.get_global_position())
		occluder_material.set_shader_param("light_radius", light.radius)

func register_light(light):
	assert(!_lights.has(light))
	_lights.append(light)

func unregister_light(light):
	assert(_lights.has(light))
	_lights.erase(light)
	
func add_occluder_quad(pos2d: Vector2, tile_size: float):
	var pos3d := Vector3(pos2d.x, pos2d.y, 0.0)
	
	var occluder_mesh_instance = _occluder_mesh_scene.instantiate()
	
	var half_size := tile_size * 0.5
	
	var points_cw := []
	points_cw.append(Vector2(-half_size, -half_size))
	points_cw.append(Vector2(half_size, -half_size))
	points_cw.append(Vector2(half_size, half_size))
	points_cw.append(Vector2(-half_size, half_size))
	
#	points_cw.reverse()
	
	occluder_mesh_instance.create_mesh(pos3d, points_cw, true, extra_cull_margin, occluder_material)
	
	occluder_mesh_instance.name = "Occluder Mesh"
	
	_shadow_viewport.add_child(occluder_mesh_instance) 
	
func add_occluder_points(pos2d: Vector2, points_cw: Array):
	var pos3d := Vector3(pos2d.x, pos2d.y, 0.0)
	
	var occluder_mesh_instance = _occluder_mesh_scene.instantiate()
	
	occluder_mesh_instance.create_mesh(pos3d, points_cw, true, extra_cull_margin, occluder_material)
	
	occluder_mesh_instance.name = "Occluder Mesh"
	
	_shadow_viewport.add_child(occluder_mesh_instance) 

func clear_occluders():
	for child in _shadow_viewport.get_children():
		if child is MeshInstance3D:
			child.queue_free()
