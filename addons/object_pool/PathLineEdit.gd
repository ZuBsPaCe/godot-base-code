@tool
extends LineEdit

func _ready():
	update_error_highlight()

func update_error_highlight():
	if _is_path_valid(text):
		modulate = Color.WHITE
	else:
		modulate = Color.RED

func _can_drop_data(at_position, data):
	return _try_get_drop_data(data) != null


func _drop_data(at_position, data):
	var path = _try_get_drop_data(data)
	if path != null:
		text = path
		emit_signal("text_changed", text)


func _try_get_drop_data(data):
	if data is Dictionary:
		var dict:Dictionary = data
		
		if dict.has("files") and dict["files"] is PackedStringArray and dict["files"].size() == 1:
			var path:String = dict["files"][0]
			
			if _is_path_valid(path):
				return path
	
	return null

func _is_path_valid(path: String) -> bool:
	return path.get_extension() == "tscn" and ResourceLoader.exists(path)
	

func _on_PathLineEdit_text_changed(new_text):
	update_error_highlight()
