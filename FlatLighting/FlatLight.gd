extends Node2D

@export var radius := 15.0

func _enter_tree():
	get_tree().current_scene.get_node("FlatLighting").register_light(self)
	
func _exit_tree():
	get_tree().current_scene.get_node("FlatLighting").unregister_light(self)
