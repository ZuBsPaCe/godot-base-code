extends CanvasLayer


const GameState := preload("res://Scripts/Tools/Examples/ExampleGameState.gd").GameState


var _music_slider: Slider
var _sound_slider: Slider


func _ready():
	# https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html
	if OS.has_feature("web"):
		get_node("%ExitButton").visible = false
	
	_music_slider = get_node("%MusicSlider")
	_sound_slider = get_node("%SoundSlider")
		

func setup(
		p_music_factor: float, 
		p_sound_factor: float):
	_music_slider.value = p_music_factor
	_sound_slider.value = p_sound_factor
	

func _on_StartButton_pressed():
	Globals.switch_game_state(GameState.GAME)


func _on_ExitButton_pressed():
	get_tree().quit()


func _on_Volume_changed(_value):
	Globals.change_volume(_music_slider.value, _sound_slider.value)
