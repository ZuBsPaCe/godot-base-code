@tool
extends VBoxContainer


const config_file = "res://inkscape_importer.json"


enum SplitType {
	DISABLED,
	SPLIT_LAYERS,
	SPLIT_GROUPS
}


class SvgItem:
	var path : String
	var target_dir : String
	var split_type : int
	var target_dpi : int
	var transform_scale : float
	var transform_center : bool
	
	func _init(
			p_path: String,
			p_target_dir: String,
			p_split_type: int,
			p_target_dpi: int,
			p_transform_scale: float,
			p_transform_center: bool):
		path = p_path
		target_dir = p_target_dir
		split_type = p_split_type
		target_dpi = p_target_dpi
		transform_scale = p_transform_scale
		transform_center = p_transform_center

@onready var _svg_mode_button := $ModeToolbar/SvgModeButton
@onready var _instance_mode_button := $ModeToolbar/InstanceModeButton
@onready var _settings_mode_button := $ModeToolbar/SettingsModeButton

@onready var _svg_mode_controls := $SvgModeControls
@onready var _instance_mode_controls := $InstanceModeControls
@onready var _settings_mode_controls := $SettingsModeControls

@onready var _svg_path_add_buttn := $SvgModeControls/SvgPathAddButton
@onready var _svg_tree := $SvgModeControls/SvgTree
@onready var _target_dir_input := $SvgModeControls/HBoxContainer2/VBoxContainer2/HBoxContainer/TargetDirInput
@onready var _target_dir_browse_button := $SvgModeControls/HBoxContainer2/VBoxContainer2/HBoxContainer/TargetDirBrowseButton
@onready var _split_options := $SvgModeControls/HBoxContainer2/VBoxContainer2/SplitOptions
@onready var _target_dpi := $SvgModeControls/HBoxContainer2/VBoxContainer2/TargetDpi
@onready var _import_button := $SvgModeControls/ImportButton

@onready var _transform_center := $InstanceModeControls/HBoxContainer1/VBoxContainer2/TransformCenter
@onready var _transform_scale := $InstanceModeControls/HBoxContainer1/VBoxContainer2/TransformScale
@onready var _apply_button := $InstanceModeControls/ApplyButton

@onready var _inkscape_path_input := $SettingsModeControls/HBoxContainer/InkscapePathInput
@onready var _inkscape_path_browse_button := $SettingsModeControls/HBoxContainer/InkscapePathBrowseButton


var editor_interface : EditorInterface


var _svg_items := []
var _last_import_dir : String
var _last_target_dir : String
var _current_inkscape_path : String


var _current_svg_item: SvgItem


var _file_dialog : EditorFileDialog

func _ready():
	_file_dialog = EditorFileDialog.new()
	_file_dialog.current_dir = "user://"
	_file_dialog.min_size.x = 1000
	_file_dialog.min_size.y = 500
	_file_dialog.theme = editor_interface.get_base_control().theme
	editor_interface.add_child(_file_dialog)
	
	_on_svg_mode_button_pressed()
	
	_load_config()


func show_file_dialog(file_mode, access, initial_dir, filter, callable: Callable):
	_file_dialog.file_mode = file_mode
	_file_dialog.access = access
	_file_dialog.current_dir = initial_dir
	_file_dialog.clear_filters()
	
	var connections = _file_dialog.file_selected.get_connections()
	for connection in connections:
		_file_dialog.file_selected.disconnect(connection["callable"])
	
	connections = _file_dialog.dir_selected.get_connections()
	for connection in connections:
		_file_dialog.dir_selected.disconnect(connection["callable"])
	
	match file_mode:
		FileDialog.FILE_MODE_OPEN_FILE:
			_file_dialog.add_filter(filter)
			_file_dialog.file_selected.connect(callable)
		FileDialog.FILE_MODE_OPEN_DIR:
			_file_dialog.dir_selected.connect(callable)
	
	_file_dialog.popup_centered()


func _on_svg_mode_button_pressed():
	_svg_mode_button.button_pressed = true
	_instance_mode_button.button_pressed = false
	_settings_mode_button.button_pressed = false
	
	_svg_mode_controls.visible = true
	_instance_mode_controls.visible = false
	_settings_mode_controls.visible = false


func _on_run_mode_button_pressed():
	_svg_mode_button.button_pressed = false
	_instance_mode_button.button_pressed = true
	_settings_mode_button.button_pressed = false
	
	_svg_mode_controls.visible = false
	_instance_mode_controls.visible = true
	_settings_mode_controls.visible = false
	

func _on_settings_mode_button_pressed():
	_svg_mode_button.button_pressed = false
	_instance_mode_button.button_pressed = false
	_settings_mode_button.button_pressed = true
	
	_svg_mode_controls.visible = false
	_instance_mode_controls.visible = false
	_settings_mode_controls.visible = true


func _on_svg_path_add_button_pressed():
	show_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, FileDialog.ACCESS_FILESYSTEM, _last_import_dir, "*.svg ; SVG Images", _on_svg_path_add_button_selected)


func _on_svg_path_add_button_selected(path):
	_svg_items.append(SvgItem.new(path, "", SplitType.DISABLED, 96, 1.0, true))
	
	_last_import_dir = get_base_dir(path)
	
	_update_svg_tree()
	_save_config()


func _on_svg_tree_item_selected():
	_current_svg_item = _svg_tree.get_selected().get_metadata(0)
	
	_target_dir_input.text = _current_svg_item.target_dir
	_split_options.select(_current_svg_item.split_type)
	_target_dpi.value = _current_svg_item.target_dpi
	_transform_scale.value = _current_svg_item.transform_scale
	_transform_center.button_pressed = _current_svg_item.transform_center
	
	_update_controls_enabled_state()


func _update_controls_enabled_state():
	var disable: bool = _current_svg_item == null
	
	_instance_mode_button.disabled = disable
	_target_dir_input.editable = !disable
	_target_dir_browse_button.disabled = disable
	_split_options.disabled = disable
	_target_dpi.editable = !disable
	_transform_scale.editable = !disable
	_import_button.disabled = disable || _current_svg_item.target_dir == ""
	_apply_button.disabled = disable || _current_svg_item.target_dir == ""


func _on_svg_tree_button_pressed(item, column, id):
	var svg_item : SvgItem = item.get_metadata(0)
	
	if _current_svg_item == svg_item:
		_current_svg_item = null
		_update_controls_enabled_state()
	
	_svg_items.erase(svg_item)
	item.free()
	
	_update_svg_tree()
	_save_config()


func _save_config():
	var file = File.new()
	file.open(config_file, File.WRITE)
	
	var serialized_svg_item := []
	for svg_item in _svg_items:
		serialized_svg_item.append({
			"path": svg_item.path,
			"target_dir": svg_item.target_dir,
			"split_type": svg_item.split_type,
			"target_dpi": svg_item.target_dpi,
			"transform_scale": svg_item.transform_scale,
			"transform_center": svg_item.transform_center})

	var config := {}
	
	config["svg_items"] = serialized_svg_item
	config["last_import_dir"] = _last_import_dir
	config["last_target_dir"] = _last_target_dir
	config["inkscape_path"] = _current_inkscape_path
	
	var json = JSON.new()
	file.store_line(json.stringify(config, "\t"))

	file.close()


func _load_config():
	var file = File.new()
	
	if file.file_exists(config_file):
		file.open(config_file, File.READ)
		var json := JSON.new()
		
		var res = json.parse(file.get_as_text())
		file.close()
		
		if res == OK:
			var config : Dictionary = json.get_data()
			
			var serialized_svg_items : Array = config["svg_items"]
			for item in serialized_svg_items:
				_svg_items.append(SvgItem.new(
					item["path"],
					item["target_dir"],
					item["split_type"],
					item["target_dpi"],
					item["transform_scale"],
					item["transform_center"]
				))
			
			_last_import_dir = config["last_import_dir"]
			_last_target_dir = config["last_target_dir"]
			_current_inkscape_path = config["inkscape_path"]
			_inkscape_path_input.text = _current_inkscape_path
		else:
			printerr("Color Swapper: Failed to parse configuration.")
	
	_current_svg_item = null
	
	_update_svg_tree()
	_update_controls_enabled_state()


func _update_svg_tree():
	_svg_tree.clear()
	
	var root_node = _svg_tree.create_item()
	
	var common_prefix
	for svg_item in _svg_items:
		if common_prefix == null:
			common_prefix = get_base_dir(svg_item.path)
		else:
			var dir : String = get_base_dir(svg_item.path)
			while common_prefix.length() > 0 && !dir.begins_with(common_prefix):
				var old_prefix = common_prefix
				var new_prefix = get_base_dir(common_prefix)
				common_prefix = new_prefix
				if old_prefix == new_prefix:
					break
	
	for i in _svg_items.size():
		var svg_item: SvgItem = _svg_items[i]
		
		var display_name := svg_item.path
		if common_prefix != null && common_prefix.length() > 0:
			display_name = display_name.substr(common_prefix.length() + 1)
		
		var node : TreeItem = _svg_tree.create_item(root_node)
		node.set_text(0, display_name)
		node.add_button(0, get_theme_icon("Remove", "EditorIcons"))
		node.set_metadata(0, svg_item)


func get_base_dir(path: String) -> String:
	# THIS IS BUGGY: print("C:/test".get_base_dir())
	# Returns "C:/t"
	
	var idx := path.rfind("/")
	if idx > 0:
		return path.substr(0, idx)
	return ""


func _on_target_dir_input_text_changed(dir):
	_current_svg_item.target_dir = dir
	_save_config()
	_update_controls_enabled_state()


func _on_target_dir_browse_button_pressed():
	show_file_dialog(FileDialog.FILE_MODE_OPEN_DIR, FileDialog.ACCESS_RESOURCES, _last_target_dir, null, _on_target_dir_browse_button_selected)


func _on_target_dir_browse_button_selected(dir):
	_target_dir_input.text = dir
	_current_svg_item.target_dir = dir
	_last_target_dir = dir
	_save_config()
	_update_controls_enabled_state()


func _on_import_button_pressed():
	var file := File.new()
	if !file.file_exists(_current_inkscape_path):
		var accept_dlg := AcceptDialog.new()
		accept_dlg.title = "Inkscape not found"
		accept_dlg.dialog_text = "Please set a path to a valid inkscape application in the settings."
		add_child(accept_dlg)
		accept_dlg.popup_centered()
		await accept_dlg.confirmed
		accept_dlg.queue_free()
		return
	
	print("Inkscape Importer: Import running!")
	
	print("Reading SVG...")
	
	# Get list of things to export
	
	var ids := _get_svg_ids()
	
	
	print("Inkscape Importer: Creating %d images..." % ids.size())
	
	# Export 
	# Dpi and Transform Scale go hand in hand double dpi 2*96 => Scale down by 0.5. Reason: 
	# Inkscape exports with anti aliasing, which you can't disable. Aliasing is cut off on border
	# pixels and you can't add a margin (only works for exporting svg, but this additional step 
	# lead to broken results)	
	
	var update_assets := false
	
	if ids.size() > 0:
		var export_actions := ""
		
		for id in ids:
			var internal_path: String = _current_svg_item.target_dir + "/" + id + ".png"
			var global_path = ProjectSettings.globalize_path(internal_path)
			
			export_actions += "export-id:" + id + "; export-id-only; export-dpi:" + str(_current_svg_item.target_dpi)+ "; export-filename:" + global_path + "; export-do;"
		
		var arg1 := "/c"
		var arg2 = "\"" + _current_inkscape_path + "\" --actions=\"" + export_actions + "\" \"" + _current_svg_item.path + "\"" 

		var output := []
		var exit_code = OS.execute("cmd.exe", [arg1, arg2], output)
		
		var resourceFileSystem := editor_interface.get_resource_filesystem()
		#resourceFileSystem.update_file(target_path)
		resourceFileSystem.scan()
		resourceFileSystem.scan_sources()
	
	print("Inkscape Importer: Import done!")


func _on_split_options_item_selected(index):
	_current_svg_item.split_type = index
	_save_config()


func _on_target_dpi_value_changed(value):
	_current_svg_item.target_dpi = value
	_save_config()


func _on_transform_scale_value_changed(value):
	_current_svg_item.transform_scale = value
	_save_config()


func _on_transform_center_toggled(button_pressed):
	_current_svg_item.transform_center = button_pressed
	_save_config()


func _on_inkscape_path_input_text_changed(new_text):
	_current_inkscape_path = new_text
	_save_config()


func _on_inkscape_path_browse_button_pressed():
	var initial_dir = "c:/program files/inkscape/bin"
	if _current_inkscape_path != null:
		initial_dir = get_base_dir(_current_inkscape_path)
	
	show_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, FileDialog.ACCESS_FILESYSTEM, initial_dir, "*.exe ; Applications", _on_inkscape_path_add_button_selected)


func _on_inkscape_path_add_button_selected(path):
	_current_inkscape_path = path
	_inkscape_path_input.text = path
	
	_save_config()


func _on_apply_button_pressed():
	print("Inkscape Importer: Apply running!")
	
	var scene_root := editor_interface.get_edited_scene_root()
	
	var ids := _get_svg_ids()
	
	var textures := []
	
	for id in ids:
		var internal_path: String = _current_svg_item.target_dir + "/" + id + ".png"
		if !ResourceLoader.exists(internal_path, "Texture"):
			printerr("Inkspace Importer: Could not find texture [%s]. Aborting." % internal_path)
			return
		
		textures.append(ResourceLoader.load(internal_path, "Texture"))
	
	var positions_and_sizes := _get_svg_positions_and_sizes(ids)
	var positions: PackedVector2Array = positions_and_sizes[0]
	var sizes: PackedVector2Array = positions_and_sizes[1]
	
	var center_offset := Vector2()
	
	if _current_svg_item.transform_center and ids.size() > 0:
		var min_corner := Vector2.ZERO
		var max_corner := Vector2.ZERO
		
		for i in ids.size():
			var position = positions[i]
			var size = sizes[i]
			
			var min_current = position - size * 0.5
			var max_current = position + size * 0.5
			
			if i == 0:
				min_corner = min_current
				max_corner = max_current
			else:
				min_corner.x = min(min_corner.x, min_current.x)
				min_corner.y = min(min_corner.y, min_current.y)
				max_corner.x = max(max_corner.x, max_current.x)
				max_corner.y = max(max_corner.y, max_current.y)
		
		center_offset = -0.5 * (max_corner + min_corner)
		
		print("Min: %s   Max: %s   Offset: %s" % [min_corner, max_corner, center_offset])
	
	
	var added := 0
	var updated := 0
	
	for i in ids.size():
		var id = "svg_" + ids[i]
		var texture = textures[i]
		var position = positions[i]
		
		var node = scene_root.find_node(id)
		
		if node == null:
			print("Adding %s" % id)
			added += 1
			
			node = Sprite2D.new()
			node.name = id
			node.texture = texture
			
			scene_root.add_child(node)
			
			node.owner = scene_root
		else:
			print("Updating %s" % id)
			updated += 1
		
		node.position = position + center_offset
		node.scale = Vector2(_current_svg_item.transform_scale, _current_svg_item.transform_scale)
		
		print("Position: %s   Size: %s    Final: %s" % [position, sizes[i], node.position])
	
	print("Inkscape Importer: Apply done! Added %d. Updated %d." % [added, updated])


func _get_svg_ids() -> PackedStringArray:
	var arg1 := "/c"
	var arg2: String
	
	var ids := PackedStringArray()
	
	match _current_svg_item.split_type:
		SplitType.SPLIT_GROUPS:
			arg2 = "\"" + _current_inkscape_path + "\" --actions=\"select-clear; select-invert:no-layers; select-list\" \"" + _current_svg_item.path + "\"" 
		SplitType.SPLIT_LAYERS:
			arg2 = "\"" + _current_inkscape_path + "\" --actions=\"select-clear; select-invert:groups; select-list\" \"" + _current_svg_item.path + "\"" 
		SplitType.DISABLED:
			arg2 = "\"" + _current_inkscape_path + "\" --actions=\"select-clear; select-by-element:svg; select-list\" \"" + _current_svg_item.path + "\"" 
		_:
			assert(false)
	
	var output := []
	var exit_code = OS.execute("cmd.exe", [arg1, arg2], output)
	
	var lines = output[0].split("\n")
	for line in lines:
		var regex = RegEx.new()
		regex.compile("(.*?) cloned:")
		var result = regex.search(line)
		if result:
			ids.append(result.get_string(1))
	
	return ids

# Returns Array[Positions, Sizes] of Type Array[PackedVector2Array, PackedVector2Array]
func _get_svg_positions_and_sizes(ids: PackedStringArray) -> Array:
	var positions := PackedVector2Array()
	var sizes := PackedVector2Array()
	
	var arg1 := "/c"
	var arg2 = "\"" + _current_inkscape_path + "\" --query-all \"" + _current_svg_item.path + "\"" 

	var output := []
	var exit_code = OS.execute("cmd.exe", [arg1, arg2], output)
	
	var lines = output[0].split("\n")
	var position_dict := {}
	var size_dict := {}
	
	var scale := Vector2.ONE * _current_svg_item.target_dpi / 96.0 * _current_svg_item.transform_scale
	
	for line in lines:
		var regex = RegEx.new()
		regex.compile("(.*?),(.*?),(.*?),(.*?),(.*)")
		var result = regex.search(line)
		var ok := false
		if result:
			var id = result.get_string(1)
			var pos = Vector2(result.get_string(2).to_float(), result.get_string(3).to_float())
			var size = Vector2(result.get_string(4).to_float(), result.get_string(5).to_float())
			
			pos *= scale
			size *= scale
			
			position_dict[id] = pos + size * 0.5
			size_dict[id] = size
			
	
	for id in ids:
		if position_dict.has(id):
			positions.append(position_dict[id])
			sizes.append(size_dict[id])
		else:
			positions.append(Vector2())
			sizes.append(Vector2())
	
	return [positions, sizes]
