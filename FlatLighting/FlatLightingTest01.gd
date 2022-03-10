extends Node2D


@onready var camera := $Camera

@onready var flat_lighting := $FlatLighting
@onready var light := $FlatLight

func _ready() -> void:
	flat_lighting.register_light(light)
	
func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			var pos2d := get_global_mouse_position()
			pos2d.y -= 100.0
			
			flat_lighting.add_occluder_quad(pos2d, 64.0)		


func _process(_delta: float) -> void:
	var player_pos := get_global_mouse_position()
	
	player_pos.x = clamp(player_pos.x, -960, 960)
	player_pos.y = clamp(player_pos.y, -540, 540)
	
	camera.position = player_pos
	light.position = get_global_mouse_position()
	
