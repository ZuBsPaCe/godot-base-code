@tool
extends VBoxContainer

const EnumItem := preload("res://addons/object_pool/enum_item.gd")
const EnumValue := preload("res://addons/object_pool/enum_value.gd")
const Helper := preload("res://addons/object_pool/helper.gd")

const config_path = "res://pool.json"


var test : EnumValue

@onready var _enum_tree := $EnumTree

var _helper


var editor_interface : EditorInterface
var _enum_items := []

func _ready():
	pass


func setup(p_editor_interface: EditorInterface):
	editor_interface = p_editor_interface
	_helper = Helper.new()
	
	_enum_items = _helper.load_config(config_path)
	for enum_item in _enum_items:
		for enum_value in enum_item.enum_values:
			enum_value.enum_value_changed.connect(_on_enum_value_changed)
	
	_update_enum_items()


func _on_AddEnumButton_pressed():
	var enum_path: String = $HBoxContainer/EnumPathInput.text
	var enum_name := _get_enum_name_from_path(enum_path)
	print("Pool: Inspecting enum [%s]" % enum_name)
	
	var enum_dict = _get_enum_dict(enum_path, enum_name)
	
	if enum_dict == null:
		printerr("Pool: Enum not found")
		return
	
	print("Pool: Enum found")
	
	_add_enum_item(enum_path, enum_name)
	_helper.save_config(config_path, _enum_items)


func _on_RefreshButton_pressed():
	_update_enum_items()


func _on_EnumTree_item_selected():
	var selected_node: TreeItem = _enum_tree.get_selected()
	if selected_node == null:
		editor_interface.get_selection().clear()
		return
	
	editor_interface.inspect_object(selected_node.get_metadata(0))


func _on_EnumTree_button_pressed(item, column, id):
	var metadata = item.get_metadata(0)
	if metadata is EnumItem:
		var dlg := ConfirmationDialog.new()
		dlg.dialog_text = "Really unregister enum %s and all values?" % metadata.name
		add_child(dlg)
		dlg.confirmed.connect(_on_EnumItem_delete_confirmed.bind(metadata))
		dlg.popup_centered()
		await dlg.popup_hide
		remove_child(dlg)

func _on_EnumItem_delete_confirmed(enum_item: EnumItem):
	print("Removing item...")
	_enum_items.erase(enum_item)
	_update_enum_items()


func _get_enum_name_from_path(path : String) -> String:
	var name := path.get_file()
	var dot_index := name.rfind(".")
	if dot_index > 0:
		name = name.substr(0, dot_index)
	
	name = name.capitalize().replace(" ", "")
	return name


# Enum Names (list of strings) => enum_dict.keys()
# Enum Values (list of ints)   =>   enum_dict.values()
func _get_enum_dict(path, name):
	var script = load(path)
	if script == null:
		return
	
	return script.get(name)


func _add_enum_item(path: String, name: String, enum_values = []) -> EnumItem:
	var enum_item := EnumItem.new(path, name, enum_values)
	_enum_items.append(enum_item)
	
	for enum_value in enum_item.enum_values:
		enum_value.connect("enum_value_changed", self, "_on_enum_value_changed")
	
	_update_enum_items()
	
	return enum_item


func _on_enum_value_changed():
	_update_enum_items()
	_helper.save_config(config_path, _enum_items)


func _update_enum_items():
	_enum_tree.clear()
	var root = _enum_tree.create_item()
	
	for enum_item in _enum_items:
		var tree_node: TreeItem = _enum_tree.create_item(root)
		tree_node.set_text(0, enum_item.name)
		tree_node.set_metadata(0, enum_item)
		tree_node.add_button(0, get_theme_icon("Remove", "EditorIcons"))
		
		var enum_dict = _get_enum_dict(enum_item.path, enum_item.name)
		for value_name in enum_dict.keys():
			
			var enum_value : EnumValue
			
			for search_enum_value in enum_item.enum_values:
				if search_enum_value.name == value_name:
					enum_value = search_enum_value
					break
			
			if enum_value == null:
				enum_value = EnumValue.new(value_name, enum_dict[value_name])
				enum_value.enum_value_changed.connect(_on_enum_value_changed)
				enum_item.enum_values.append(enum_value)
			
			var value_node: TreeItem = _enum_tree.create_item(tree_node)
			value_node.set_text(0, value_name)
			value_node.set_metadata(0, enum_value)
			
			if enum_value.scene != null:
				value_node.set_text(1, "=> " + _get_enum_name_from_path(enum_value.scene.resource_path))
