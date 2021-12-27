@tool
extends EditorPlugin

var dock

func _enter_tree():
	print("Pool editor starting")
	
	dock = preload("res://addons/object_pool/pool_dock.tscn").instantiate()
	
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)
	
	dock.setup(get_editor_interface())
	
	print("Pool editor started")


func _exit_tree():
	print("Pool editor stopping")
	
	remove_control_from_docks(dock)
	
	print("Pool editor stopped")
