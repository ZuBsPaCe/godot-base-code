@tool
extends WindowDialog

onready var _color_picker := $MarginContainer/VBoxContainer/ColorPicker

var color : Color setget _set_color, _get_color

signal unset_color()
signal apply_color(color)

func _ready():
	pass


func _set_color(value):
	_color_picker.color = value


func _get_color():
	return _color_picker.color

func _on_ColorSelectorCloseButton_pressed():
	hide()

func _on_ApplyButton_pressed():
	emit_signal("apply_color", self.color)

func _on_UnsetButton_pressed():
	emit_signal("unset_color")
