@tool
extends EditorPlugin

var dock

func _enter_tree():
	print("Inkscape importer starting")
	
	dock = preload("res://addons/inkscape_importer/inkscape_importer_dock.tscn").instantiate()
	dock.editor_interface = get_editor_interface()
	
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)
	
	print("Inkscape importer started")


func _exit_tree():
	print("Inkscape importer stopping")
	
	remove_control_from_docks(dock)
	
	print("Inkscape importer stopped")
