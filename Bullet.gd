extends Node2D

onready var rc := $RayCast2D

func shoot(exception_node : Node2D, max_dist : float):
	rc.cast_to = Vector2(max_dist, 0)
	rc.add_exception(exception_node)
	rc.force_raycast_update()
	
	var collider = rc.get_collider()
	
	if collider:
		$Line2D.points = [Vector2(), Vector2((rc.get_collision_point() - global_position).length(), 0)]
	else:
		$Line2D.points = [Vector2(), Vector2(max_dist,0)]
