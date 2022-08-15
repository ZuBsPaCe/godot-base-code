extends Node2D

@export var priority := 1

@export var texture: Texture2D
@export var radius := 5.0

@export var create_debug_sprite := false

@export var color := Color.WHITE

@export var auto_hide := true

var handle

var _visibility_notifier: VisibleOnScreenNotifier2D


func _exit_tree():
	if handle != null:
		unregister()

func _ready():
	if auto_hide:
		_visibility_notifier = VisibleOnScreenNotifier2D.new()
		add_child(_visibility_notifier)
		var texture_size := texture.get_size()
		_visibility_notifier.rect = Rect2(-texture_size / 2, texture_size)
		_visibility_notifier.screen_entered.connect(_on_visible_on_screen_notifier_2d_screen_entered)
		_visibility_notifier.screen_exited.connect(_on_visible_on_screen_notifier_2d_screen_exited)
	else:
		register()


	if create_debug_sprite:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://FlatLighting/LightCookies/alpha_128.png")
		var debug_scale := radius / 64.0
		sprite.scale = Vector2(debug_scale, debug_scale)
		sprite.modulate = color
		add_child(sprite)


func update_radius(p_radius: float):
	radius = p_radius
	if handle != null:
		FlatLightingLocator.flat_lighting.update_light_radius(handle, p_radius)
	
func register():
	assert(handle == null)
	handle = FlatLightingLocator.flat_lighting.register_light(global_position, radius, texture, color, priority, self)
	
func unregister():
	assert(handle != null)
	FlatLightingLocator.flat_lighting.unregister_light(handle)
	handle = null

func _on_visible_on_screen_notifier_2d_screen_entered():
	register()

func _on_visible_on_screen_notifier_2d_screen_exited():
	unregister()
