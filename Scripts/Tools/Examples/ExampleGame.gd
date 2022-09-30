extends Node2D


const GameState := preload("res://Scripts/Tools/Examples/ExampleGameState.gd").GameState

@export var player_scene:PackedScene
@export var _initial_game_state := GameState.MAIN_MENU

@onready var _game_state := $GameStateMachine


func _ready():
	Globals.setup()
	State.setup()
	Effects.setup($Camera2D)
	
	set_fullscreen(Globals.get_setting(Globals.SETTING_FULLSCREEN))
	
	$MainMenu.setup(
		Globals.get_setting(Globals.SETTING_MUSIC_VOLUME),
		Globals.get_setting(Globals.SETTING_SOUND_VOLUME))
	
	$MainMenu.visible = false
	$GameOverlay.visible = false
	
	$MainMenu.switch_game_state.connect(switch_game_state)
	$MainMenu.change_volume.connect(change_volume)
	$GameOverlay.switch_game_state.connect(switch_game_state)
	
	get_viewport().size_changed.connect(on_viewport_resized)
	
	_game_state.setup(
		_initial_game_state,
		_on_GameStateMachine_enter_state,
		Callable(),
		_on_GameStateMachine_exit_state)


func _process(delta):
	if _game_state.current != GameState.GAME:
		return
	
	$Dummy.position += $Dummy.position.direction_to(Globals.get_global_mouse_position()) * 100.0 * delta
	$Dummy.rotation = -PI * 0.5 + $Dummy.position.angle_to_point(Globals.get_global_mouse_position())


func _input(event):
	if event is InputEventKey:
		if event.pressed and not event.echo and event.alt_pressed and event.keycode == KEY_ENTER:
			set_fullscreen(!Tools.is_fullscreen())


func on_viewport_resized():	
	if !Tools.is_fullscreen():
		var window_size := DisplayServer.window_get_size()
		Globals.set_setting(Globals.SETTING_WINDOW_WIDTH, window_size.x)
		Globals.set_setting(Globals.SETTING_WINDOW_HEIGHT, window_size.y)
		Globals.save_settings()
		

func switch_game_state(new_state):
	_game_state.set_state(new_state)


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


func _on_GameStateMachine_enter_state():
	match _game_state.current:
		GameState.MAIN_MENU:
			$MainMenu.visible = true
			Effects.shake(Vector2.RIGHT)

		GameState.GAME:
			State.on_game_start()
			$GameOverlay.visible = true
			Effects.shake(Vector2.RIGHT)

		_:
			assert(false, "Unknown game state")


func _on_GameStateMachine_exit_state():
	match _game_state.current:
		GameState.MAIN_MENU:
			$MainMenu.visible = false

		GameState.GAME:
			State.on_game_stopped()
			$GameOverlay.visible = false

		_:
			assert(false, "Unknown game state")
