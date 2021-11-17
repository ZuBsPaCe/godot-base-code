tool
extends EditorPlugin

var dock

func _enter_tree():
	print("ColorSwapper starting")
	
	dock = preload("res://addons/color_swapper/color_swapper_dock.tscn").instance()
	dock.editor_interface = get_editor_interface()
	
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	
	print("ColorSwapper started")


func _exit_tree():
	print("ColorSwapper stopping")
	
	remove_control_from_docks(dock)
	
	print("ColorSwapper stopped")