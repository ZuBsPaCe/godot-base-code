extends Node

@export var texture: Texture2D
@export var radius := 5.0

@export var create_source_sprite := false
@export var source_sprite_color := Color.YELLOW

var handle

func _enter_tree():
	FlatLightingLocator.flat_lighting.register_occluder(self)
	
	if create_source_sprite:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://FlatLighting/LightCookies/alpha_128.png")
		var scale := radius / Globals.TILE_SIZE
		sprite.scale = Vector2(scale, scale)
		sprite.modulate = source_sprite_color
		add_child(sprite)
	
func _exit_tree():
	FlatLightingLocator.flat_lighting.unregister_light(handle)

