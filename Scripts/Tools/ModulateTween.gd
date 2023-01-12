class_name ModulateTween
extends RefCounted


var _root_node
var _ease_type
var _trans_type

var _affected_nodes := []
var _tween: Tween
var _root_node_set_visible: bool
var _latest_color: Color


func _init(root_node, initial_color: Color, ease_type := Tween.EASE_OUT_IN, trans_type := Tween.TRANS_SINE):
	_root_node = root_node
	_ease_type = ease_type
	_trans_type = trans_type
	
	if root_node is CanvasItem:
		_affected_nodes.append(_root_node)
		_root_node_set_visible = false
	else:
		for child in root_node.get_children():
			if child is CanvasItem:
				_affected_nodes.append(child)
		
		if root_node is CanvasLayer:
			_root_node_set_visible = true
	
	assert(_affected_nodes.size() > 0)
	
	set_immediate(initial_color)


# Can yield
func tween(color: Color, duration: float):
	var tween_was_running := false
	
	if _tween != null:
		tween_was_running = _tween.is_running()
		_tween.kill()
		
	if duration > 0.0:
		
		if (!tween_was_running and
			color.a == _latest_color.a && 
			color.r == _latest_color.r &&
			color.g == _latest_color.g && 
			color.b == _latest_color.b):
			await _root_node.get_tree().process_frame
			return
						
		_latest_color = color
		
		var visible := color.a > 0.0

		# This will inherit the pause mode of the root node.
		_tween = _root_node\
			.create_tween()\
			.set_ease(_ease_type)\
			.set_trans(_trans_type)
		
		for node in _affected_nodes:
			_tween.parallel().tween_property(node, "modulate", color, duration)
			
			if visible:
				node.visible = true
			else:
				_tween.tween_callback(node.set_visible.bind(false))
		
		if _root_node_set_visible:
			if visible:
				_root_node.visible = true
			else:
				_tween.tween_callback(_root_node.set_visible.bind(false))
				
		await _tween.finished
	else:
		set_immediate(color)
		await Globals.get_tree().process_frame
			
			
func set_immediate(color: Color):
	if _tween != null:
		_tween.kill()
		_tween = null
		
	var visible := color.a > 0.0
	
	for node in _affected_nodes:
		node.visible = visible
		node.modulate = color
	
	if _root_node_set_visible:
		_root_node.visible = visible
	
	_latest_color = color	
