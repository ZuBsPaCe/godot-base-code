@tool
extends VBoxContainer

const config_file = "res://map_generator.json"

@onready var _generator_script_edit := $HBoxContainer/GeneratorScriptEdit
@onready var _browse_generator_script_button := $HBoxContainer/BrowseGeneratorScriptButton
@onready var _seed_edit := $HBoxContainer2/VBoxContainer2/SeedEdit
@onready var _width_num := $HBoxContainer2/VBoxContainer2/WidthNum
@onready var _height_num := $HBoxContainer2/VBoxContainer2/HeightNum
@onready var _level_num := $HBoxContainer2/VBoxContainer2/LevelNum
@onready var _generate_button := $GenerateButton
@onready var _clear_button := $ClearButton

var editor_interface : EditorInterface

var _file_dialog : EditorFileDialog

var _generate_script_path: String
var _seed: String
var _width: int
var _height: int
var _level: int

func _ready():
	_file_dialog = EditorFileDialog.new()
	_file_dialog.current_dir = "user://"
	_file_dialog.min_size.x = 1000
	_file_dialog.min_size.y = 500
	_file_dialog.theme = editor_interface.get_base_control().theme
	editor_interface.add_child(_file_dialog)
	
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


func _save_config():
	var file = File.new()
	file.open(config_file, File.WRITE)

	var config := {}
	
	config["generate_script_path"] = _generate_script_path
	config["seed"] = _seed
	config["width"] = _width
	config["height"] = _height
	config["level"] = _level
	
	var json = JSON.new()
	file.store_line(json.stringify(config, "\t"))

	file.close()
	
	_update_controls_enabled_state()


func _load_config():
	
	_seed = ""
	_width = 16
	_height = 16
	_level = 1
	
	var file = File.new()
	
	if file.file_exists(config_file):
		file.open(config_file, File.READ)
		var json := JSON.new()
		
		var res = json.parse(file.get_as_text())
		file.close()
		
		if res == OK:
			var config : Dictionary = json.get_data()
			
			if config.has("generate_script_path"):
				_generate_script_path = config["generate_script_path"]
			
			if config.has("seed"):
				_seed = config["seed"]
				
			if config.has("width"):
				_width = config["width"]
				
			if config.has("height"):
				_height = config["height"]
				
			if config.has("level"):
				_level = config["level"]
				
		else:
			printerr("MapGenerator: Failed to parse configuration.")
	
	_generator_script_edit.text = _generate_script_path
	_seed_edit.text = _seed
	_width_num.value = _width
	_height_num.value = _height
	_level_num.value = _level
	
	_update_controls_enabled_state()


func _update_controls_enabled_state():
	_generate_button.disabled = _generate_script_path.is_empty()


func _on_generator_script_edit_text_changed(new_text):
	_generate_script_path = new_text
	_save_config()


func _on_browse_generator_script_button_pressed():
	show_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, FileDialog.ACCESS_RESOURCES, "res://", "*.gd ; Script", _on_browse_generator_script_file_selected)


func _on_browse_generator_script_file_selected(path: String):
	_generator_script_edit.text = path
	_generate_script_path = path
	_save_config()


func _on_generate_button_pressed():
	print("MapGenerator: Starting")
	
	var signature := "func generate(scene: Node, seed: String, width: int, height: int, level: int):"
	var arg_count := 5
	
	var instance = _load_generator_script("generate", signature, arg_count)
	if instance == null:
		return

	var scene := get_tree().edited_scene_root
	
	instance.generate(scene, _seed, _width, _height, _level)
	
	print("MapGenerator: Done")


func _on_clear_button_pressed():
	print("MapGenerator: Clearing")
	
	var signature := "func clear(scene: Node):"
	var arg_count := 1
	
	var instance = _load_generator_script("clear", signature, arg_count)
	if instance == null:
		return

	var scene := get_tree().edited_scene_root
	
	instance.clear(scene)
	
	print("MapGenerator: Done")


func _load_generator_script(method_name: String, signature: String, arg_count: int):
	var generate_script = ResourceLoader.load(_generate_script_path)
	
	if generate_script == null:
		printerr("MapGenerator: Failed to load script [%s]" % _generate_script_path)
		return
	
	if not generate_script is GDScript:
		printerr("MapGenerator: This is not a GDScript [%s]" % _generate_script_path)
		return
	
	if not generate_script.is_tool():
		printerr("MapGenerator: Please add @tool to the top of the script [%s]" % _generate_script_path)
		return

	
	var method_found := false
	var args_match := false
	for method in generate_script.get_script_method_list():
		print("Debug: %s" % method.name)
		if method.name == method_name:
			method_found = true
			if method.args.size() == arg_count:
				args_match = true
			break
	
	
	if not method_found:
		printerr("MapGenerator: Please add a '%s' method to script [%s]" % [method_name, _generate_script_path])
		print("MapGenerator: Expected signature is: %s" % signature)
		return
	
	if not args_match:
		printerr("MapGenerator: '%s' method hast wrong arguments in script [%s]" % [method_name, _generate_script_path])
		print("MapGenerator: Expected signature is: %s" % signature)
		return
	
	print("MapGenerator: Loaded script [%s]" % _generate_script_path)
	
	var instance = generate_script.new()
	return instance


func _on_seed_edit_text_changed(new_text):
	_seed = new_text
	_save_config()


func _on_width_num_value_changed(value):
	_width = int(value)
	_save_config()


func _on_height_num_value_changed(value):
	_height = int(value)
	_save_config()


func _on_level_num_value_changed(value):
	_level = int(value)
	_save_config()

