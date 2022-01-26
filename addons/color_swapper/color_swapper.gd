@tool
extends EditorPlugin

var dock

func _enter_tree():
	print("ColorSwapper editor starting")
	
	dock = preload("res://addons/color_swapper/color_swapper_dock.tscn").instantiate()
	dock.editor_interface = get_editor_interface()
	
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	
	print("ColorSwapper editor started")


func _exit_tree():
	print("ColorSwapper editor stopping")
	
	remove_control_from_docks(dock)
	
	print("ColorSwapper editor stopped")
