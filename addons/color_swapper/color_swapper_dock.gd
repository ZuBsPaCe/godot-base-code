@tool
extends VBoxContainer

@export var color_box_scene : PackedScene
@export var color_selector_scene : PackedScene


const config_file = "res://color_swapper.json"


class PaletteItem:
	var initialized : bool
	var color : Color
	var part_ids : Array
	
	func _init(p_initialized: bool, p_color: Color, p_part_ids: Array):
		initialized = p_initialized
		color = p_color
		part_ids = p_part_ids
	
	func empty() -> bool:
		return !initialized && color.to_html() == "ff000000" && part_ids.empty()


class ImageItem:
	var filename : String
	var path : String
	var col_to_part_id := {}
	
	func _init(p_path: String, p_filename: String):
		path = p_path
		filename = p_filename


class PathItem:
	var path : String
	var target_dir : String
	var image_items := []
	
	func _init(p_path: String, p_target_dir: String):
		path = p_path
		target_dir = p_target_dir


onready var _part_mode_button := $ModeToolbar/PartModeButton
onready var _palette_mode_button := $ModeToolbar/PaletteModeButton
onready var _image_mode_button := $ModeToolbar/ImageModeButton
onready var _run_mode_button := $ModeToolbar/RunModeButton

onready var _part_mode_controls := $PartModeControls
onready var _palette_mode_controls := $PaletteModeControls
onready var _image_mode_controls := $ImageModeControls
onready var _run_mode_controls := $RunModeControls

onready var _part_add_input := $PartModeControls/HBoxContainer/PartAddInput
onready var _part_add_button := $PartModeControls/HBoxContainer/PartAddButton
onready var _part_tree := $PartModeControls/PartTree

onready var _palette_grid := $PaletteModeControls/ScrollContainer/PaletteGrid
onready var _palette_grid_width := $PaletteModeControls/HBoxContainer/PaletteWidth
onready var _palette_grid_height := $PaletteModeControls/HBoxContainer/PaletteHeight
onready var _palette_part_options := $PaletteModeControls/HBoxContainer2/PalettePartOptions
onready var _palette_part_add_button := $PaletteModeControls/HBoxContainer2/PalettePartAddButton
onready var _palette_part_tree := $PaletteModeControls/PalettePartTree
onready var _palette_edit_color_button := $PaletteModeControls/PaletteEditColorButton

onready var _image_preview := $ImageModeControls/ImagePreview
onready var _image_tree := $ImageModeControls/ImageTree
onready var _image_target_input := $ImageModeControls/HBoxContainer/ImageTargetInput
onready var _image_target_browse_button := $ImageModeControls/HBoxContainer/ImageTargetBrowseButton
onready var _image_color_tree := $ImageModeControls/ImageColorTree
onready var _image_part_options := $ImageModeControls/ImagePartOptions

onready var _run_autorun_checkbox := $RunModeControls/AutoRunCheckbox

var editor_interface : EditorInterface

var _parts := {}
var _parts_root_item : TreeItem
var _parts_items := {}


var _palette_index := -1
var _palette_items := []
var _palette_color_boxes := []
var _palette_color_selector : WindowDialog
var _palette_part_options_hovered := false


var _image_path_items := []
var _image_color_counts := {}

var _autorun := false
var _modified_times := {}

var _folder_dialog : FileDialog

func _ready():
	_palette_color_selector = color_selector_scene.instance()
	_palette_color_selector.connect("unset_color", self, "_on_palette_color_selector_unset_color")
	_palette_color_selector.connect("apply_color", self, "_on_palette_color_selector_apply_color")
	_palette_color_selector.set_position(get_viewport().size / 2.0 - _palette_color_selector.rect_size / 2.0)
	editor_interface.add_child(_palette_color_selector)
	
	_folder_dialog = FileDialog.new()
	_folder_dialog.mode = FileDialog.MODE_OPEN_DIR
	_folder_dialog.current_dir = "user://"
	_folder_dialog.popup_exclusive = true
	_folder_dialog.rect_min_size.y = 500
	_folder_dialog.resizable = true
	_folder_dialog.filters = PoolStringArray(["*.png ; PNG Images", "*.bmp ; Bitmap Images"])
	editor_interface.add_child(_folder_dialog)
	
	_on_PartModeButton_pressed()
	
	_load_config()


func _notification(what: int):
	if what == NOTIFICATION_WM_FOCUS_IN:
		if _autorun:
			var perform_autorun := false
			
			var file := File.new()
			for path_index in _image_path_items.size():
				var path_item: PathItem = _image_path_items[path_index]
				
				for image_index in path_item.image_items.size():
					var image_item: ImageItem = path_item.image_items[image_index]
					if file.file_exists(image_item.path):
						var last_time = _modified_times.get(image_item.path)
						if last_time == null || last_time < file.get_modified_time(image_item.path):
							perform_autorun = true
							break
				
				if perform_autorun:
					break
			
			if perform_autorun:
				_on_RunButton_pressed()


func show_folder_dialog(access, callback_func):
	_folder_dialog.access = access
	
	if _folder_dialog.is_connected("dir_selected", self, "_on_ImageTargetBrowseButton_selected"):
		_folder_dialog.disconnect("dir_selected", self, "_on_ImageTargetBrowseButton_selected")
	
	if _folder_dialog.is_connected("dir_selected", self, "_on_ImagePathAddButton_selected"):
		_folder_dialog.disconnect("dir_selected", self, "_on_ImagePathAddButton_selected")
	
	assert(["_on_ImageTargetBrowseButton_selected", "_on_ImagePathAddButton_selected"].has(callback_func))
	
	_folder_dialog.connect("dir_selected", self, callback_func)
	
	_folder_dialog.popup_centered()


func _on_PartModeButton_pressed():
	_part_mode_button.pressed = true
	_palette_mode_button.pressed = false
	_image_mode_button.pressed = false
	_run_mode_button.pressed = false
	
	_part_mode_controls.visible = true
	_palette_mode_controls.visible = false
	_image_mode_controls.visible = false
	_run_mode_controls.visible = false


func _on_PaletteModeButton_pressed():
	_part_mode_button.pressed = false
	_palette_mode_button.pressed = true
	_image_mode_button.pressed = false
	_run_mode_button.pressed = false
	
	_part_mode_controls.visible = false
	_palette_mode_controls.visible = true
	_image_mode_controls.visible = false
	_run_mode_controls.visible = false


func _on_ImageModeButton_pressed():
	_part_mode_button.pressed = false
	_palette_mode_button.pressed = false
	_image_mode_button.pressed = true
	_run_mode_button.pressed = false
	
	_part_mode_controls.visible = false
	_palette_mode_controls.visible = false
	_image_mode_controls.visible = true
	_run_mode_controls.visible = false


func _on_RunModeButton_pressed():
	_part_mode_button.pressed = false
	_palette_mode_button.pressed = false
	_image_mode_button.pressed = false
	_run_mode_button.pressed = true
	
	_part_mode_controls.visible = false
	_palette_mode_controls.visible = false
	_image_mode_controls.visible = false
	_run_mode_controls.visible = true
	

func _on_PartAddInput_text_changed(new_text):
	_update_PartAddInput_state()


func _update_PartAddInput_state():
	if _part_add_input.text.empty():
		_part_add_button.disabled = true
		return
	
	if _parts.values().has(_part_add_input.text):
		_part_add_button.disabled = true
		return
	
	_part_add_button.disabled = false


func _on_PartAddButton_pressed():
	_part_add_button.disabled = true
	
	var new_id := 0
	
	for existing_id in _parts.keys():
		if existing_id > new_id:
			new_id = existing_id
			
	new_id += 1
	
	_add_part(new_id, _part_add_input.text)
	_save_config()
	
	_update_selected_palette_item()
	

func _add_part(part_id: int, part_name: String):
	_parts[part_id] = part_name
	
	if _parts_root_item == null:
		_parts_root_item = _part_tree.create_item()
	
	# See: https://github.com/godotengine/godot/tree/master/editor/icons
	var remove_icon = get_icon("Remove", "EditorIcons")
	
	var item : TreeItem = _part_tree.create_item(_parts_root_item)
	item.set_text(0, part_name)
	item.add_button(0, remove_icon, part_id)
	
	_parts_items[part_id] = item

func _on_PartTree_button_pressed(item, column, id):
	for palette_item in _palette_items:
		palette_item.part_ids.erase(id)
	
	for path_item in _image_path_items:
		for image_item in path_item.image_items:
			var remove_cols := []
			for col in image_item.col_to_part_id.keys():
				if image_item.col_to_part_id[col] == id:
					image_item.col_to_part_id.erase(col)
	
	_parts.erase(id)
	
	_parts_items[id].free()
	_parts_items.erase(id)
	
	_save_config()
	
	_update_PartAddInput_state()
	_update_palette_grid()
	_update_image_preview()

func _set_grid_size(width: int, height: int):
	_palette_grid_width.value = width
	_palette_grid_height.value = height
	
	_save_config()
	
	_update_palette_grid()

func _update_palette_grid():
	print("Updating grid of size %d x %d" % [_palette_grid_width.value, _palette_grid_height.value ])
	
	for color_box in _palette_color_boxes:
		color_box.queue_free()
	
	_palette_color_boxes.clear()
	
	var item_count : int = _palette_grid_width.value * _palette_grid_height.value
	while _palette_items.size() < item_count:
		_palette_items.append(PaletteItem.new(false, Color.black, []))
	
	_palette_grid.columns = _palette_grid_width.value
	
	var index := 0
	for x in _palette_grid_width.value:
		for y in _palette_grid_height.value:
			var color_box = color_box_scene.instance()
			color_box.setup(_palette_items[index].initialized, _palette_items[index].color)
			_palette_grid.add_child(color_box)
			
			_palette_color_boxes.append(color_box)
			
			color_box.connect("pressed", self, "_color_box_selected", [index])
			color_box.connect("gui_input", self, "_color_box_gui_input")
			
			index += 1
	
	_palette_index = -1
	_update_selected_palette_item()


func _color_box_selected(index):
	_palette_index = index
	
	for i in _palette_color_boxes.size():
		_palette_color_boxes[i].pressed = i == index
	
	_update_selected_palette_item()


func _color_box_gui_input(ev):
	if ev is InputEventMouseButton && ev.button_index == 1 && ev.pressed && ev.doubleclick:
		_on_PaletteEditColorButton_pressed()


func _on_PaletteEditColorButton_pressed():
	var selected_color_box = _palette_color_boxes[_palette_index]
	
	if (	_palette_color_selector.rect_global_position.x > get_viewport().size.x ||
			_palette_color_selector.rect_global_position.y > get_viewport().size.y):
		_palette_color_selector.set_position(get_viewport().size / 2.0 - _palette_color_selector.rect_size / 2.0)
	
	if selected_color_box.initialized:
		_palette_color_selector.color = selected_color_box.color
	
	_palette_color_selector.show()


func _update_selected_palette_item():
	print("_update_selected_palette_item")
	
	_palette_part_options.clear()
	_palette_part_tree.clear()
	
	if _palette_index < 0:
		_palette_edit_color_button.disabled = true
		_palette_part_options.disabled = true
		_palette_part_add_button.disabled = true
		return
	
	var palette_item : PaletteItem = _palette_items[_palette_index]
	
	for part_id in _parts.keys():
		if palette_item.part_ids.has(part_id):
			continue
			
		var assigned_hint := ""
		if _get_palette_index_of_part(part_id) >= 0:
			assigned_hint = " (assigned)"
			
		_palette_part_options.add_item(_parts[part_id] + assigned_hint, part_id)
	
	var root_item = _palette_part_tree.create_item()
	for part_id in palette_item.part_ids:
		# See: https://github.com/godotengine/godot/tree/master/editor/icons
		var remove_icon = get_icon("Remove", "EditorIcons")
		
		var item : TreeItem = _palette_part_tree.create_item(root_item)
		
		item.set_text(0, _parts[part_id])
		item.add_button(0, remove_icon, part_id)
	
	_palette_edit_color_button.disabled = false
	_palette_part_options.disabled = false
	_palette_part_add_button.disabled = _palette_part_options.get_item_count() == 0
	
	_update_selected_palette_part()

func _update_selected_palette_part():
	for color_box in _palette_color_boxes:
		color_box.self_modulate = Color.white
	
	if !_palette_part_options_hovered:
		return
	
	var part_id: int = _palette_part_options.get_selected_id()
	var found_index := _get_palette_index_of_part(part_id)
	
	if found_index < 0 || found_index >= _palette_color_boxes.size():
		return
	
	_palette_color_boxes[found_index].self_modulate = Color(0.0, 0.0, 0.0)


func _get_palette_index_of_part(part_id: int) -> int:
	for index in _palette_items.size():
		var palette_item: PaletteItem = _palette_items[index]
		if palette_item.part_ids.has(part_id):
			return index
	
	return -1


func _on_PalettePartOptions_item_selected(index):
	_update_selected_palette_part()


func _on_PalettePartOptions_mouse_entered():
	_palette_part_options_hovered = true
	_update_selected_palette_part()


func _on_PalettePartOptions_mouse_exited():
	_palette_part_options_hovered = false
	_update_selected_palette_part()


func _on_PalettePartAddButton_pressed():
	var part_id: int = _palette_part_options.get_selected_id()
	
	for palette_item in _palette_items:
		palette_item.part_ids.erase(part_id)
	
	var palette_item : PaletteItem = _palette_items[_palette_index]
	palette_item.part_ids.append(part_id)
	
	_save_config()
	
	_update_selected_palette_item()


func _on_PalettePartTree_button_pressed(item, column, id):
	var palette_item : PaletteItem = _palette_items[_palette_index]
	palette_item.part_ids.erase(id)
	
	_save_config()
	
	_update_selected_palette_item()
	

func _on_palette_color_selector_unset_color():
	if _palette_index < 0:
		return
		
	_palette_items[_palette_index].initialized = false
	_palette_color_boxes[_palette_index].initialized = false
	_save_config()


func _on_palette_color_selector_apply_color(color):
	if _palette_index < 0:
		return
		
	_palette_items[_palette_index].color = color
	_palette_items[_palette_index].initialized = true
	_palette_color_boxes[_palette_index].color = color
	_save_config()


#func _add_palette_part(part_id: int, part_name: String):
#	_parts[part_id] = part_name
#
#	if _parts_root_item == null:
#		_parts_root_item = _part_tree.create_item()
#
#	# See: https://github.com/godotengine/godot/tree/master/editor/icons
#	var remove_icon = get_icon("Remove", "EditorIcons")
#
#	var item : TreeItem = _part_tree.create_item(_parts_root_item)
#	item.set_text(0, part_name)
#	item.add_button(0, remove_icon, part_id)
#
#	_parts_items[part_id] = item


func _save_config():
	var file = File.new()
	file.open(config_file, File.WRITE)
	
	var serialized_parts := []
	for id in _parts.keys():
		serialized_parts.append(
			{
				"id": id,
				"name": _parts[id]
			})
	
	var serialized_palette_items := []
	var max_palette_count := int(_palette_grid_width.value) * int(_palette_grid_height.value)
	
	for palette_item in _palette_items:
		if palette_item.empty():
			continue

		serialized_palette_items.append(
			{
				"initialized": palette_item.initialized,
				"color": palette_item.color.to_html(),
				"part_ids": palette_item.part_ids
			})
	
	var serialized_paths := []
	for path_item in _image_path_items:
		var serialized_images := []
		for image_item in path_item.image_items:
			var serialized_colored_parts := []
			for col in image_item.col_to_part_id.keys():
				var part_id = image_item.col_to_part_id[col]
				if part_id == 0:
					continue
				serialized_colored_parts.append({
					"color": col,
					"part_id": part_id
				})
			
			serialized_images.append({
				"filename": image_item.filename,
				"path": image_item.path,
				"colored_parts": serialized_colored_parts
			})
		
		serialized_paths.append(
			{
				"path": path_item.path,
				"target_dir": path_item.target_dir,
				"images": serialized_images
			})
	
	var config := {}
	
	config["parts"] = serialized_parts
	config["grid_width"] = int(_palette_grid_width.value)
	config["grid_height"] = int(_palette_grid_height.value)
	config["palette_items"] = serialized_palette_items
	config["paths"] = serialized_paths
	config["autorun"] = _autorun
	
	file.store_line(JSON.print(config, "\t"))

	file.close()
	
	if _autorun:
		_on_RunButton_pressed()

func _load_config():
	var file = File.new()
	
	var grid_width := int(_palette_grid_width.value)
	var grid_height := int(_palette_grid_height.value)
	
	if file.file_exists(config_file):
		file.open(config_file, File.READ)
		var config : Dictionary = parse_json(file.get_as_text())
		file.close()
		
		_autorun = config["autorun"]
		_run_autorun_checkbox.pressed = _autorun
		
		var serialized_parts : Array = config["parts"]
		for part in serialized_parts:
			_add_part(part["id"], part["name"])
		
		if config.has("palette_items"):
			var serialized_palette_items : Array = config["palette_items"]
			for palette_item in serialized_palette_items:
				var part_ids := []
				for part_id in palette_item["part_ids"]:
					part_ids.append(int(part_id))
				_palette_items.append(PaletteItem.new(palette_item["initialized"], Color(palette_item["color"]), part_ids))
		
		_palette_grid_width.value = config["grid_width"]
		_palette_grid_height.value = config["grid_height"]
		
		var serialized_paths : Array = config["paths"]
		for serialized_path in serialized_paths:
			var path_item := PathItem.new(serialized_path["path"], serialized_path["target_dir"])
			
			for serialized_image in serialized_path["images"]:
				var image_item := ImageItem.new(serialized_image["path"], serialized_image["filename"])
				
				for serialized_colored_parts in serialized_image["colored_parts"]:
					var col = serialized_colored_parts["color"]
					image_item.col_to_part_id[col] = int(serialized_colored_parts["part_id"])
				
				path_item.image_items.append(image_item)
			
			_image_path_items.append(path_item)
	
	_update_palette_grid()
	_update_selected_palette_item()
	_update_image_tree()


func _on_PaletteHeight_value_changed(value):
	_set_grid_size(
		int(_palette_grid_width.value), 
		int(_palette_grid_height.value))


func _on_PaletteWidth_value_changed(value):
	_set_grid_size(
		int(_palette_grid_width.value), 
		int(_palette_grid_height.value))


func _on_PaletteHeight_changed():
	_set_grid_size(
		int(_palette_grid_width.value), 
		int(_palette_grid_height.value))


func _on_PaletteWidth_changed():
	_set_grid_size(
		int(_palette_grid_width.value), 
		int(_palette_grid_height.value))


func _on_ImagePathAddButton_pressed():
	show_folder_dialog(FileDialog.ACCESS_FILESYSTEM, "_on_ImagePathAddButton_selected")


func _on_ImagePathAddButton_selected(dir):
	_image_path_items.append(PathItem.new(dir, ""))
	
	_update_image_tree()
	_save_config()

func _update_image_tree():
	_image_tree.clear()
	
	var root_item = _image_tree.create_item()
	
	var short_image_paths := []
	var common_prefix
	for path_item in _image_path_items:
		if common_prefix == null:
			common_prefix = get_base_dir(path_item.path)
		else:
			var dir : String = path_item.path.get_base_dir()
			while common_prefix.length() > 0 && !dir.begins_with(common_prefix):
				var old_prefix = common_prefix
				var new_prefix = get_base_dir(common_prefix)
				print(new_prefix)
				common_prefix = new_prefix
				if old_prefix == new_prefix:
					break
	
	for i in _image_path_items.size():
		var path_item: PathItem = _image_path_items[i]
		
		var display_name := path_item.path
		if common_prefix != null && common_prefix.length() > 0:
			display_name.erase(0, common_prefix.length() + 1)
		
		var section_item : TreeItem = _image_tree.create_item(root_item)
		section_item.set_text(0, display_name)
		section_item.add_button(0, get_icon("Remove", "EditorIcons"))
		section_item.set_metadata(0, path_item)
		
		var dir = Directory.new()
		dir.open(path_item.path)
		dir.list_dir_begin()
		
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break
			
			if file_name.begins_with("."):
				continue
			
			var ext = file_name.get_extension()
			
			if ext != "png" and ext != "bmp":
				continue
				
			var tree_item : TreeItem = _image_tree.create_item(section_item)
			tree_item.set_text(0, file_name)
			
			var image_item: ImageItem = null
			for other_image_item in path_item.image_items:
				if other_image_item.filename.nocasecmp_to(file_name) == 0:
					image_item = other_image_item
			
			if image_item == null:
				image_item = ImageItem.new(path_item.path + "/" + file_name, file_name)
				path_item.image_items.append(image_item)
				
			tree_item.set_metadata(0, image_item)
				
		dir.list_dir_end()
	
	_update_image_preview()


func _on_ImageTree_button_pressed(item, column, id):
	var path_item : PathItem = item.get_metadata(0)
	_image_path_items.erase(path_item)
	item.free()
	
	_update_image_tree()
	_save_config()

func get_base_dir(path: String) -> String:
	# THIS IS BUGGY: print("C:/test".get_base_dir())
	# Returns "C:/t"
	
	var idx := path.find_last("/")
	if idx > 0:
		return path.substr(0, idx)
	return ""


func _on_ImageTree_item_selected():
	_update_image_preview()


func _update_image_preview():
	_image_preview.texture = null
	_image_part_options.disabled = true
	_image_target_input.text = ""
	_image_target_input.editable = false
	_image_target_browse_button.disabled = true
	
	var tree_item = _image_tree.get_selected()
	if tree_item == null:
		return
	
	var metadata = tree_item.get_metadata(0)
	
	if metadata is PathItem:
		var path_item : PathItem = metadata
		_image_target_input.text = path_item.target_dir
		_image_target_input.editable = true
		_image_target_browse_button.disabled = false
	
	elif metadata is ImageItem:
		var path_item : PathItem = tree_item.get_parent().get_metadata(0)
		_image_target_input.text = path_item.target_dir
		
		var image_item : ImageItem = metadata
		
		var image: Image
		
		if image_item.path.begins_with("res://"):
			var stream_texture = ResourceLoader.load(image_item.path)
			image = stream_texture.get_data()
		else:
			image = Image.new()
			image.load(image_item.path)
		
		var texture := ImageTexture.new()
		texture.create_from_image(image, 0)
		
		_image_preview.texture = texture
		
		_image_color_tree.clear()
		
		image.lock()
		
		var width := image.get_width()
		var height := image.get_height()
		
		_image_color_counts = {}
		var color_array := []
		
		for y in height:
			for x in width:
				var col := image.get_pixel(x, y)
				if !_image_color_counts.has(col):
					_image_color_counts[col] = 1
					color_array.append(col)
				else:
					_image_color_counts[col] += 1
		
		color_array.sort_custom(self, "sort_colors")
		
		image.unlock()
		
		_image_color_tree.set_column_title(0, "Count")
		_image_color_tree.set_column_title(1, "R")
		_image_color_tree.set_column_title(2, "G")
		_image_color_tree.set_column_title(3, "B")
		_image_color_tree.set_column_title(4, "A")
		_image_color_tree.set_column_title(5, "Part")
		_image_color_tree.set_column_titles_visible(true)
		
		var root_item = _image_color_tree.create_item()
		
		for col in color_array:
			var num = _image_color_counts[col]
			var color_item = _image_color_tree.create_item(root_item)
			color_item.set_text_align(1,TreeItem.ALIGN_CENTER)
			color_item.set_text_align(2,TreeItem.ALIGN_CENTER)
			color_item.set_text_align(3,TreeItem.ALIGN_CENTER)
			color_item.set_text_align(4,TreeItem.ALIGN_CENTER)
			
			color_item.set_text(0, "%d" % num)
			color_item.set_text(1, "%d" % col.r8)
			color_item.set_text(2, "%d" % col.g8)
			color_item.set_text(3, "%d" % col.b8)
			
			if col.a8 != 255:
				color_item.set_text(4, "%d" % col.a8)
			
			if image_item.col_to_part_id.has(col.to_html()):
				color_item.set_text(5, _parts[image_item.col_to_part_id[col.to_html()]])

			color_item.set_metadata(0, col)


func sort_colors(a, b):
	var count_a = _image_color_counts[a]
	var count_b = _image_color_counts[b]
	if count_a < count_b:
		return false
	if count_a > count_b:
		return true
	
	return a.to_rgba32() < b.to_rgba32()


func _on_ImageColorTree_item_selected():
	var col: Color = _image_color_tree.get_selected().get_metadata(0)
	_image_preview.material.set_shader_param("selected_col", col)
	
	var tree_item = _image_tree.get_selected()
	var image_item: ImageItem = tree_item.get_metadata(0)
	
	_image_part_options.clear()
	_image_part_options.add_item("Skip", -1)
	
	var selected_part_id := 0
	if image_item.col_to_part_id.has(col.to_html()):
		selected_part_id = image_item.col_to_part_id[col.to_html()]
	
	var select_index := 0
	var index := 0
	
	for part_id in _parts.keys():
		index += 1
		_image_part_options.add_item(_parts[part_id], part_id)
		if selected_part_id == part_id:
			select_index = index
	
	_image_part_options.disabled = false
	_image_part_options.select(select_index)


func _on_ImagePreview_mouse_entered():
	_image_preview.material.set_shader_param("cycle_enabled", true)


func _on_ImagePreview_mouse_exited():
	_image_preview.material.set_shader_param("cycle_enabled", false)


func _on_ImagePartOptions_item_selected(index):
	var col: Color = _image_color_tree.get_selected().get_metadata(0)
	
	var tree_item = _image_tree.get_selected()
	var image_item: ImageItem = tree_item.get_metadata(0)
	
	var part_id = _image_part_options.get_item_id(index)
	var color_item = _image_color_tree.get_selected()
	
	if part_id > 0:
		image_item.col_to_part_id[col.to_html()] = part_id
		color_item.set_text(5, _parts[part_id])
	else:
		image_item.col_to_part_id.erase(col.to_html())
		color_item.set_text(5, "")
	
	_save_config()


func _on_ImageTargetBrowseButton_pressed():
	if _image_target_input.text.length() > 0:
		_folder_dialog.current_dir = _image_target_input.text
	
	show_folder_dialog(FileDialog.ACCESS_RESOURCES, "_on_ImageTargetBrowseButton_selected")


func _on_ImageTargetBrowseButton_selected(dir):
	_image_target_input.text = dir
	_set_image_target_dir(dir)


func _on_ImageTargetInput_text_changed(new_text):
	_set_image_target_dir(new_text)


func _set_image_target_dir(dir: String):
	print("Setting Target Dir [%s]" % dir)
	
	if _image_target_input.text != dir:
		_image_target_input.text = dir
		return
	
	var tree_item = _image_tree.get_selected()
	if tree_item == null:
		return
	
	var metadata = tree_item.get_metadata(0)
	
	if metadata is PathItem:
		var path_item: PathItem = metadata
		
		if path_item.target_dir != dir:
			path_item.target_dir = dir
			print("Saving Target Dir [%s]" % dir)
			_save_config()


func _on_RunButton_pressed():
	print("Color Swapper: Running!")
	
	var dir := Directory.new()
	var file := File.new()
	
	
	var part_id_to_col := {}
	for palette_index in _palette_items.size():
		var palette_item: PaletteItem = _palette_items[palette_index]
		for part_id in palette_item.part_ids:
			assert(!part_id_to_col.has(part_id))
			part_id_to_col[part_id] = palette_item.color
			print("Part ID %d => %s" % [part_id, palette_item.color])

	for path_index in _image_path_items.size():
		var path_item: PathItem = _image_path_items[path_index]
		if path_item.target_dir.length() == 0:
			printerr("Color Swapper: Target dir not set for input [%s]." % path_item.path)
			continue
		if !dir.dir_exists(path_item.target_dir):
			printerr("Color Swapper: Target dir [%s] not found for input [%s]." % [path_item.target_dir, path_item.path])
			continue
		
		for image_index in path_item.image_items.size():
			var image_item: ImageItem = path_item.image_items[image_index]
			
			print("Color Swapper: Processing [%s]" % image_item.path)
			
			_modified_times[image_item.path] = file.get_modified_time(image_item.path)
			
			var image: Image
			if image_item.path.begins_with("res://"):
				var stream_texture = ResourceLoader.load(image_item.path)
				image = stream_texture.get_data()
			else:
				image = Image.new()
				image.load(image_item.path)
			
			image.lock()
			
			var width := image.get_width()
			var height := image.get_height()
			for y in height:
				for x in width:
					var col := image.get_pixel(x, y).to_html()
					var part_id = image_item.col_to_part_id.get(col)
					if part_id == null:
						continue
					var new_col = part_id_to_col[part_id]
					if new_col == null:
						continue
					image.set_pixel(x, y, new_col)
			
			image.unlock()
			
			var target_path: String = path_item.target_dir + "/" + image_item.filename
			image.save_png(target_path)
			
			
#			var resourceFileSystem := editor_interface.get_resource_filesystem()
#			resourceFileSystem.update_file(target_path)
			
#			var res = ResourceLoader.load(target_path)
#			print(res)
			
#			var omg = ResourceSaver.save(target_path, image)
#			print(omg)
	
#	yield(get_tree(), "idle_frame")
	
	var resourceFileSystem := editor_interface.get_resource_filesystem()
	#resourceFileSystem.update_file(target_path)
	resourceFileSystem.scan()
	resourceFileSystem.scan_sources()
	
	print("Color Swapper: Done!")


func _on_AutoRunCheckbox_toggled(button_pressed):
	_autorun = $RunModeControls/AutoRunCheckbox.pressed
	_save_config()
