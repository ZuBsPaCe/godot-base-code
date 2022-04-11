extends Node2D

func _ready():
	$SubViewportContainer.material.set_shader_param("flat_light_tex", FlatLightingLocator.flat_lighting.get_texture())
	$SubViewportContainer/SubViewport/FlatLightingTest01/Overlay.visible = false
