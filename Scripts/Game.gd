extends Node2D

enum GameState {
	NONE,
	MAIN_MENU,
	GAME
}


@export var player_scene:PackedScene


func _ready():

	Globals.setup(
		$Camera2D,
		$EntityContainer,
		player_scene
	)
	
	call_deferred("switch_game_state", GameState.ART1)


func switch_game_state(new_state) -> void:
	match new_state:
		GameState.MAIN_MENU:
			pass

		GameState.GAME:
			pass

		_:
			assert(false, "Unknown game state")
