extends Node2D

@export var texture: Texture2D
@export var radius := 5.0

@export var create_debug_sprite := false

@export var color := Color.WHITE

var handle

func _enter_tree():
	register()
	
	if create_debug_sprite:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://FlatLighting/LightCookies/alpha_128.png")
		var scale := radius / 64.0
		sprite.scale = Vector2(scale, scale)
		sprite.modulate = color
		add_child(sprite)
	
func _exit_tree():
	if handle != null:
		FlatLightingLocator.flat_lighting.unregister_light(handle)
		handle = null

func update_radius(p_radius: float):
	radius = p_radius
	if handle != null:
		FlatLightingLocator.flat_lighting.update_light_radius(handle, p_radius)
	
func register():
	assert(handle == null)
	handle = FlatLightingLocator.flat_lighting.register_light(global_position, radius, texture, color, self)
	
func unregister():
	assert(handle != null)
	FlatLightingLocator.flat_lighting.unregister_light(handle)
	handle = null

