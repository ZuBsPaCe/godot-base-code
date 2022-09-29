extends CanvasLayer


const GameState := preload("res://Scripts/Tools/Examples/ExampleGameState.gd").GameState


signal switch_game_state(new_state)


func _on_MainMenuButton_pressed():
	emit_signal("switch_game_state", GameState.MAIN_MENU)
