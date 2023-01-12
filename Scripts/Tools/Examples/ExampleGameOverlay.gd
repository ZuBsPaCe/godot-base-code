extends CanvasLayer


const GameState := preload("res://Scripts/Tools/Examples/ExampleGameState.gd").GameState


func _on_MainMenuButton_pressed():
	Globals.switch_game_state(GameState.MAIN_MENU)
