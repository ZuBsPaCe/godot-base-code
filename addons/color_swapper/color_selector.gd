@tool
extends Window

@onready var _color_picker := $MarginContainer/VBoxContainer/ColorPicker

var color : Color:
	get:
		return _color_picker.color
	set(value):
		_color_picker.color = value

signal unset_color()
signal apply_color(color)

func _ready():
	pass


func _on_ColorSelectorCloseButton_pressed():
	hide()

func _on_ApplyButton_pressed():
	emit_signal("apply_color", self.color)

func _on_UnsetButton_pressed():
	emit_signal("unset_color")
