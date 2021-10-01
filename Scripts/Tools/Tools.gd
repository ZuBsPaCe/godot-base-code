extends Node2D

var _raycast : RayCast2D


func _ready():
    _raycast = RayCast2D.new()
    _raycast.enabled = false
    add_child(_raycast)



# Array Helpers

func rand_item(array : Array) -> Object:
	return array[randi() % array.size()]

func rand_pop(array : Array) -> Object:
	var index := randi() % array.size()
	var object = array[index]
	array.remove(index)
	return object


# Raycast Helpers

func raycast_dir(from: PhysicsBody2D, dir: Vector2, view_distance: float) -> Object:
    assert(dir.is_equal_approx(dir.normalized()), "Vector is not normalized!")

#	raycast.clear_exceptions()
#	raycast.add_exception(from)

    _raycast.position = from.position
    _raycast.cast_to = from.position + dir * view_distance
    _raycast.collision_mask = from.collision_mask

    _raycast.force_raycast_update()

    return _raycast.get_collider()


func raycast_to(from: PhysicsBody2D, to: PhysicsBody2D, view_distance: float) -> bool:
#	raycast.clear_exceptions()
#	raycast.add_exception(from)

    _raycast.position = from.position
    _raycast.cast_to = (from.position - to.position).clamped(view_distance)
    _raycast.collision_mask = from.collision_mask

    _raycast.force_raycast_update()

    return _raycast.get_collider() == to