extends Node2D

@onready var camera := $Camera

@onready var flat_lighting := $FlatLighting
@onready var mouse_light := $MouseLight
@onready var overlay := $Overlay
@onready var create_debug_sprites := false

var _light_bodies := []

#func _ready():
#	$Overlay.texture = $FlatLighting.light_viewport
#	assert($Overlay.texture != null)

func _unhandled_input(event: InputEvent):	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			var pos2d := get_global_mouse_position()
			pos2d.y -= 100.0
			
			var points_cw = flat_lighting.get_occluder_quad(64.0)
			
			var polygon := Polygon2D.new()
			polygon.polygon = PackedVector2Array(points_cw)
			polygon.color = Color.DARK_BLUE
			
			var collision := CollisionPolygon2D.new()
			collision.polygon = PackedVector2Array(points_cw)
			
			var static_body := StaticBody2D.new()
			static_body.add_child(collision)
			
			static_body.add_child(polygon)
			static_body.position = pos2d
			
			flat_lighting.register_occluder(pos2d, points_cw, true, static_body)
			
			$OccluderContainer.add_child(static_body)
			
			print("Occluder added")
	
	elif event is InputEventKey:
		if event.pressed and !event.echo:
			if event.keycode == KEY_KP_ADD:
				_on_add_button_pressed()
			elif event.keycode == KEY_KP_SUBTRACT:
				_on_remove_button_pressed()
			

func _process(_delta: float) -> void:
	var player_pos := get_global_mouse_position()
	
	player_pos.x = clamp(player_pos.x, -960, 960)
	player_pos.y = clamp(player_pos.y, -540, 540)
	
	camera.position = player_pos
	mouse_light.position = get_global_mouse_position()
	
	overlay.position = flat_lighting.get_camera_center()



func _on_add_button_pressed():

	var light_textures := [
		"res://FlatLighting/LightCookies/light_128_normal.png",
		"res://FlatLighting/LightCookies/light_256_normal.png",
		"res://FlatLighting/LightCookies/light_1024_smooth.png",
		"res://FlatLighting/LightCookies/light_1024_normal.png"
	]
	
	var light_tex: String = light_textures[randi() % light_textures.size()]

	var circle := CircleShape2D.new()
	
	if light_tex.contains("1024"):
		circle.radius = 64.0
	elif light_tex.contains("256"):
		circle.radius = 32.0
	elif light_tex.contains("128"):
		circle.radius = 16.0
	
	var shape := CollisionShape2D.new()
	
	var physic_material := PhysicsMaterial.new()
	physic_material.bounce = 1.0
	
	var body := RigidDynamicBody2D.new()
	body.gravity_scale = 0.0
	body.physics_material_override = physic_material
	
	var shape_id = body.create_shape_owner(body)
	body.shape_owner_add_shape(shape_id, circle)

	
	var light = load("res://FlatLighting/FlatLight.tscn").instantiate()
	
	
	light.texture = load(light_tex)
	light.radius = circle.radius * 0.9
	light.create_debug_sprite = create_debug_sprites
	
	var color_luck := _light_bodies.size() % 3
	match color_luck:
		0:
			light.color = Color.RED
		1:
			light.color = Color.GREEN
		2:
			light.color = Color.BLUE
	
	body.add_child(shape)
	body.add_child(light)
	
	$LightContainer.add_child(body)
	
	_light_bodies.append(body)
	
	print("Light added")


func _on_remove_button_pressed():
	if _light_bodies.is_empty():
		return
		
	_light_bodies.pop_back().queue_free()
	
	print("Light removed")
