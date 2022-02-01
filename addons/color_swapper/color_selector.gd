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


func _on_color_selector_close_requested():
	hide()

func _on_apply_button_pressed():
	emit_signal("apply_color", color)

func _on_unset_button_pressed():
	emit_signal("unset_color")

func _on_close_button_pressed():
	hide()
