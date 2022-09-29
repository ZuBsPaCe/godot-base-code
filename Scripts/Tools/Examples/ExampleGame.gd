extends Node2D


const GameState := preload("res://Scripts/Tools/Examples/ExampleGameState.gd").GameState

@export var player_scene:PackedScene

@onready var _game_state := $GameStateMachine



func _ready():
	Globals.setup()
	State.setup()
	Effects.setup($Camera2D)
	
	$MainMenu.visible = false
	$GameOverlay.visible = false
	
	$MainMenu.switch_game_state.connect(switch_game_state)
	$GameOverlay.switch_game_state.connect(switch_game_state)
	
	_game_state.setup(
		GameState.MAIN_MENU,
		_on_GameStateMachine_enter_state,
		Callable(),
		_on_GameStateMachine_exit_state)


func _process(delta):
	if _game_state.current != GameState.GAME:
		return
	
	$Dummy.position += $Dummy.position.direction_to(Globals.get_global_mouse_position()) * 100.0 * delta
	$Dummy.rotation = -PI * 0.5 + $Dummy.position.angle_to_point(Globals.get_global_mouse_position())


func switch_game_state(new_state):
	_game_state.set_state(new_state)


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
