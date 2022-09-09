extends Node2D

enum GameState {
	NONE,
	MAIN_MENU,
	GAME
}


@export var player_scene:PackedScene

@onready var _game_state := $GameStateMachine


func _ready():

	Global.setup(
		$Camera2D,
		$EntityContainer,
		player_scene
	)
	
	_game_state.setup(
		GameState.MAIN_MENU,
		_on_GameStateMachine_enter_state,
		Callable(),
		Callable())


func _on_GameStateMachine_enter_state():
	match _game_state.current:
		GameState.MAIN_MENU:
			pass

		GameState.GAME:
			pass

		_:
			assert(false, "Unknown game state")
