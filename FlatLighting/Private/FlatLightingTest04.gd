extends Node2D

var active_node : Node2D
var active_light

func _ready():
	$FlatLighting.register_occluder(
		$LineOccluder.global_position,
		Array($LineOccluder/LineOccluder/Polygon2D.polygon),
		false,
		$LineOccluder)


func _process(delta):
	if active_node != null && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		active_node.position = get_global_mouse_position()
	
	_debug_shader(delta)
	

var _debug := 0.0
	
func _debug_shader(delta):
	_debug += delta
	if _debug < 2.0:
		return
	_debug = 0.0
	
	var vertex : Vector2 = $LineOccluder.position + $LineOccluder/LineOccluder/Polygon2D.polygon[1]
	var light_pos : Vector2 = $LeftLight.position
	var v := vertex - light_pos
	
	
	
	var a: float = 1.0 / v.dot(v)
	var b: float = 1.0 / ($LeftLight/LeftLight.radius * v.length())
	
	print("v: %s  a: %s  b: %s" % [v, a, b])
	
	var axis1 := a * v
	var axis2 := Vector2(-b * v.y, b * v.x)
	
	print("axis1: %s" % axis1)
	print("axis2: %s" % axis2)
	
	var mat1 := Transform2D(axis1, axis2, Vector2.ZERO)
#	print(mat1)
#
#	print(mat1.inverse())


	var mouse_pos := get_global_mouse_position()
	var mouse_vec := mouse_pos - vertex
	
	v = mat1 * mouse_vec
	print(v)
	

	if v.x > 0.0:
		var val = clamp(v.y / v.x, -1.0, 1.0)
		print(val)
	else:
		print("clipped")	
#
#	return (v[0] > 0.0 ? soften(clamp(v[1]/v[0], -1.0, 1.0)) : clipped);
#}
#
#void fragment(){
#	// World position of fragment.
#	vec2 position = fragProjected.xy / fragProjected.w;
#
#	// Only shade points within the edge! 
#	// In the calculation, everything is constant except world position! For an
#	//  explanation see fragClip in thes vertex shader!
#	if (dot(fragNormal, position) < fragClip) {
#		// position is inside of the occluder edge.
#
#		float occlusionA = edgef(edgeAFrag, position - prevVertexFrag, 1.0);
	
	print("")

func _unhandled_input(event):	
	if event is InputEventKey:
		if event.keycode == KEY_KP_ADD:
			if active_node != null and active_light != null:
				if active_node.scale.x <= 1.0: 
					active_node.scale += Vector2.ONE * 0.1
				else:
					active_node.scale += Vector2.ONE * 0.5
				
				active_light.update_radius(active_node.scale.x * 64.0)
				
		
		if event.keycode == KEY_KP_SUBTRACT:
			if active_node != null and active_light != null:
				if active_node.scale.x <= 1.0: 
					active_node.scale -= Vector2.ONE * 0.1
				else:
					active_node.scale -= Vector2.ONE * 0.5
				if active_node.scale.x < 0.1:
					active_node.scale = Vector2.ONE * 0.1
				active_light.update_radius(active_node.scale.x * 64.0)


func _on_left_light_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == 1 && event.pressed:
			active_node = $LeftLight
			active_light = $LeftLight/LeftLight
		elif event.button_index == 2 && event.pressed:
			if $LeftLight/LeftLight.handle != null:
				$LeftLight/LeftLight.unregister()
			else:
				$LeftLight/LeftLight.register()


func _on_right_light_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == 1 && event.pressed:
			active_node = $RightLight
			active_light = $RightLight/RightLight
		elif event.button_index == 2 && event.pressed:
			if $RightLight/RightLight.handle != null:
				$RightLight/RightLight.unregister()
			else:
				$RightLight/RightLight.register()


func _on_line_occluder_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == 1 && event.pressed:
			active_node = $LineOccluder
			active_light = null
