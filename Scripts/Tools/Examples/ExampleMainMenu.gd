extends CanvasLayer


const GameState := preload("res://Scripts/Tools/Examples/ExampleGameState.gd").GameState


signal switch_game_state(new_state)


func _ready():
	# https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html
	if OS.has_feature("web"):
		get_node("%ExitButton").visible = false
	

func _on_StartButton_pressed():
	emit_signal("switch_game_state", GameState.GAME)


func _on_ExitButton_pressed():
	get_tree().quit()
