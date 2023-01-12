extends Node


@onready var _main_menu := $MainMenu
@onready var _game_overlay := $GameOverlay

@onready var _modulate_game_overlay := ModulateTween.new($GameOverlay, Color.TRANSPARENT)
@onready var _modulate_transition_overlay := ModulateTween.new($TransitionOverlay, Color.BLACK)
@onready var _modulate_main_menu := ModulateTween.new($MainMenu, Color.TRANSPARENT)


func _ready():
	Globals.setup()
	State.setup()
	
	set_fullscreen(Globals.get_setting(Globals.SETTING_FULLSCREEN))
	
	_main_menu.setup(
		Globals.get_setting(Globals.SETTING_MUSIC_VOLUME),
		Globals.get_setting(Globals.SETTING_SOUND_VOLUME))
	
	_main_menu.visible = false
	_game_overlay.visible = false
	
	Globals.change_volume_requested.connect(change_volume)
	
	get_viewport().size_changed.connect(on_viewport_resized)


# According to docs, unhandled input should be used for player movement, because
# the gui can handle the event in _input first. It's also a good place for
# fallback shortcuts like ALT+ENTER.
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and not event.echo and event.alt_pressed and event.keycode == KEY_ENTER:
			set_fullscreen(!Tools.is_fullscreen())


# Can yield
func set_transition_overlay(color: Color, duration: float):
	await _modulate_transition_overlay.tween(color, duration)
	

# Can yield
func show_main_menu(duration: float):
	await _modulate_main_menu.tween(Color.WHITE, duration)

# Can yield
func hide_main_menu(duration: float):
	await _modulate_main_menu.tween(Color.TRANSPARENT, duration)


# Can yield
func show_game_overlay(duration: float):
	await _modulate_game_overlay.tween(Color.WHITE, duration)

# Can yield
func hide_game_overlay(duration: float):
	await _modulate_game_overlay.tween(Color.TRANSPARENT, duration)
	

func on_viewport_resized():	
	if !Tools.is_fullscreen():
		var window_size := DisplayServer.window_get_size()
		Globals.set_setting(Globals.SETTING_WINDOW_WIDTH, window_size.x)
		Globals.set_setting(Globals.SETTING_WINDOW_HEIGHT, window_size.y)
		Globals.save_settings()
		
		
func set_fullscreen(enabled: bool):		
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
		DisplayServer.window_set_size(Vector2i(
			Globals.get_setting(Globals.SETTING_WINDOW_WIDTH),
			Globals.get_setting(Globals.SETTING_WINDOW_HEIGHT)))
	
	Globals.set_setting(Globals.SETTING_FULLSCREEN, enabled)
	Globals.save_settings()
	

func change_volume(music_factor: float, sound_factor: float):
	AudioServer.set_bus_volume_db(1, linear_to_db(music_factor))
	AudioServer.set_bus_volume_db(2, linear_to_db(sound_factor))
	
	Globals.set_setting(Globals.SETTING_MUSIC_VOLUME, music_factor)
	Globals.set_setting(Globals.SETTING_SOUND_VOLUME, sound_factor)
	Globals.save_settings()
