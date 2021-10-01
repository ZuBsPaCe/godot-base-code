extends Node2D

enum GameState {
	NONE,
	MAIN_MENU,
	GAME
}


export var player_scene:PackedScene


func _ready():

	Globals.setup(
		$Camera2D,
		$EntityContainer,
		player_scene
	)
	
	switch_game_state(GameState.MAIN_MENU)


func switch_game_state(new_state) -> void:
	match new_state:
		GameState.MAIN_MENU:
			pass

		GameState.GAME:
			pass

		_:
			assert(false, "Unknown game state %s" % new_state)
