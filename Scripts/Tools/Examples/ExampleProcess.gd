extends Node


onready var _main_menu := $MainMenu
onready var _game_overlay := $GameOverlay

onready var _modulate_game_overlay := ModulateTween.new($GameOverlay, Color.transparent)
onready var _modulate_transition_overlay := ModulateTween.new($TransitionOverlay, Color.black)
onready var _modulate_main_menu := ModulateTween.new($MainMenu, Color.transparent)


func _ready():
	Globals.setup()
	State.setup()
	
	set_fullscreen(Globals.get_setting(Globals.SETTING_FULLSCREEN))
	
	_main_menu.setup(
		Globals.get_setting(Globals.SETTING_MUSIC_VOLUME),
		Globals.get_setting(Globals.SETTING_SOUND_VOLUME))
	
	_main_menu.visible = false
	_game_overlay.visible = false
	
	Globals.connect("change_volume_requested", self, "change_volume")
	
	get_tree().connect("screen_resized", self, "on_screen_resized")


# According to docs, unhandled input should be used for player movement, because
# the gui can handle the event in _input first. It's also a good place for
# fallback shortcuts like ALT+ENTER.
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and not event.echo and event.alt and event.scancode == KEY_ENTER:
			set_fullscreen(!OS.window_fullscreen)


# Can yield
func set_transition_overlay(color: Color, duration: float):
	yield(_modulate_transition_overlay.tween(color, duration), "completed")
	

# Can yield
func show_main_menu(duration: float):
	yield(_modulate_main_menu.tween(Color.white, duration), "completed")

# Can yield
func hide_main_menu(duration: float):
	yield(_modulate_main_menu.tween(Color.transparent, duration), "completed")


# Can yield
func show_game_overlay(duration: float):
	yield(_modulate_game_overlay.tween(Color.white, duration), "completed")

# Can yield
func hide_game_overlay(duration: float):
	yield(_modulate_game_overlay.tween(Color.transparent, duration), "completed")
	

func on_screen_resized():
	if !OS.window_fullscreen:
		Globals.set_setting(Globals.SETTING_WINDOW_WIDTH, OS.window_size.x)
		Globals.set_setting(Globals.SETTING_WINDOW_HEIGHT, OS.window_size.y)
		Globals.save_settings()
		

func set_fullscreen(enabled: bool):		
	if OS.window_fullscreen == enabled:
		return
	
	OS.window_fullscreen = enabled
	
	if !OS.window_fullscreen:
		OS.window_size = Vector2(
			Globals.get_setting(Globals.SETTING_WINDOW_WIDTH),
			Globals.get_setting(Globals.SETTING_WINDOW_HEIGHT))
	
	Globals.set_setting(Globals.SETTING_FULLSCREEN, OS.window_fullscreen)
	Globals.save_settings()


func change_volume(music_factor: float, sound_factor: float):
	AudioServer.set_bus_volume_db(1, linear2db(music_factor))
	AudioServer.set_bus_volume_db(2, linear2db(sound_factor))
	
	Globals.set_setting(Globals.SETTING_MUSIC_VOLUME, music_factor)
	Globals.set_setting(Globals.SETTING_SOUND_VOLUME, sound_factor)
	Globals.save_settings()
