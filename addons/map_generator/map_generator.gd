@tool
extends EditorPlugin

var dock

func _enter_tree():
	print("MapGenerator editor starting")
	
	dock = preload("res://addons/map_generator/map_generator_dock.tscn").instantiate()
	dock.editor_interface = get_editor_interface()
	
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	
	print("MapGenerator editor started")


func _exit_tree():
	print("MapGenerator editor stopping")
	
	remove_control_from_docks(dock)
	
	print("MapGenerator editor stopped")
