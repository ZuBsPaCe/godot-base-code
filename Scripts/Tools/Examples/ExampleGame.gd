extends Node2D


const GameState := preload("res://Scripts/Tools/Examples/ExampleGameState.gd").GameState


export(GameState) var _initial_game_state := GameState.MAIN_MENU


onready var _runner: Runner

var game_running := false


func _ready():	
	Effects.setup($Camera2D)


func _process(delta):
	if game_running:
		$Dummy.position += $Dummy.position.direction_to(Globals.get_global_mouse_position()) * 100.0 * delta
	$Dummy.rotation = -PI * 0.5 + $Dummy.position.angle_to_point(Globals.get_global_mouse_position())


# Can yield
func start(runner: Runner):
	game_running = false
	
	runner.create_tween(self).tween_property($Dummy, "position", Tools.get_visible_rect().get_center(), 1.0)
	if !yield(runner, "proceed"):
		return
	
	runner.create_timer(self, 1.0)
	if !yield(runner, "proceed"):
		return
	
	game_running = true
