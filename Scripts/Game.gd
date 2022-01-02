extends Node2D

enum GameState {
	NONE,
	MAIN_MENU,
	GAME
}


@export var player_scene:PackedScene

@onready var _game_state := $GameStateMachine


func _ready():

	Globals.setup(
		$Camera2D,
		$EntityContainer,
		player_scene
	)
	
	_game_state.set_state(GameState.MAIN_MENU)


func _on_GameStateMachine_enter_state(p_state):
	match p_state:
		GameState.MAIN_MENU:
			pass

		GameState.GAME:
			pass

		_:
			assert(false, "Unknown game state")
