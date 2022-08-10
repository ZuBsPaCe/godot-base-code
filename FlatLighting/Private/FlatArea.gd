extends Node2D

@export var texture: Texture2D
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


func register():
	assert(handle == null)
	handle = FlatLightingLocator.flat_lighting.register_area(global_position, texture, self)
	
func unregister():
	assert(handle != null)
	FlatLightingLocator.flat_lighting.unregister_area(handle)
	handle = null

func _on_visible_on_screen_notifier_2d_screen_entered():
	register()

func _on_visible_on_screen_notifier_2d_screen_exited():
	unregister()
